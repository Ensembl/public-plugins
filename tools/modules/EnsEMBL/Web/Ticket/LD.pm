=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2024] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Web::Ticket::LD;

use strict;
use warnings;

use List::Util qw(first uniq);
use Scalar::Util qw(looks_like_number);
use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::Job::LD;

use parent qw(EnsEMBL::Web::Ticket);

sub init_from_user_input {
  ## Abstract method implementation
  my $self      = shift;
  my $hub       = $self->hub;
  my $species   = $hub->param('species');
  my $method    = first { $hub->param($_) } qw(file url text);
  my $joined_output_file_name = 'ALL';

  # if no data entered
  throw exception('InputError', 'No input data has been entered') unless $method;

  # build input file and data
  my $description = sprintf 'LD analysis of %s in %s', ($hub->param('name') || ($method eq 'text' ? 'pasted data' : ($method eq 'url' ? 'data from URL' : sprintf("%s", $hub->param('file'))))), $species;

  # Get file content and name
  
  my ($file_content, $file_name) = $self->get_input_file_content($method);

  # if no data found in file/url
  throw exception('InputError', "No input data is present") unless $file_content;

  my $input_lines = parse_input($file_content);
  my @populations = $hub->param('populations');

  throw exception('InputError', 'Select at least one population') unless (scalar @populations > 0);

  my $adaptor = $self->hub->get_adaptor('get_PopulationAdaptor', 'variation', $species);

  my $result_headers = {};
  my @output_file_names = ();

  # check r2 and d_prime values
  my $r2 = $hub->param('r2');
  throw exception('InputError', "r2 needs to be between 0.0 and 1.0") if ( $r2 < 0.0 || $r2 > 1.0);
  throw exception('InputError', "r2 is not a number") if (!looks_like_number($r2));

  my $d_prime = $hub->param('d_prime');
  throw exception('InputError', "D' needs to be between 0.0 and 1.0") if ( $d_prime < 0.0 || $d_prime > 1.0);
  throw exception('InputError', "D' is not a number") if (!looks_like_number($d_prime));

  my $window_size = $hub->param('window_size');
  throw exception('InputError', "Window size is not a number") if (!looks_like_number($window_size));
  throw exception('InputError', "Window size needs to be between 1 and 500000") if ( $window_size < 0.0 || $window_size > 500_000);

  if ($hub->param('ld_calculation') eq 'pairwise' || $hub->param('ld_calculation') eq 'center') {
    foreach my $input_line (@$input_lines) {
      throw exception('InputError', 'Wrong input format. Expecting rs variant identifiers as input.') unless ($input_line =~ /^rs/);
    }
  }

  my $job_data = { map { my @val = $hub->param($_); $_ => @val > 1 ? \@val : $val[0] } grep { $_ !~ /^text/ && $_ ne 'file' } $hub->param };

  if ($hub->param('ld_calculation') eq 'region') {
    my @input = uniq @$input_lines;
    throw exception('InputError', 'List exceeds number of allowed regions (20) for LD calculation') if (scalar @input > 20);
    my @regions = ();
    foreach my $input_line (@input) {
      my ($chromosome, $start, $end) = split /\s+/, $input_line;  
      throw exception('InputError', 'Wrong input format. A region needs to be defined by sequence name start end. For example 5 62797383 63627669') unless ($chromosome && $start && $end);
      throw exception('InputError', 'Input region size exceeds 500000bp') if ($end - $start + 1 > 500000);
      push @regions, "$chromosome\_$start\_$end";
    }
    foreach my $name (@populations) {
      my $population = $adaptor->fetch_by_name($name);
      my $population_id = $population->dbID;
      foreach my $region (@regions) {
        my ($chr, $start, $end) = split/_/, $region;
        $result_headers->{"$population_id\_$region"} = "Population <em>$name</em> Region <em>$chr:$start-$end</em>";
        push @output_file_names, "$population_id\_$region";
      }
    }  
  }
  elsif ($hub->param('ld_calculation') eq 'pairwise') {
    my @input_variants = uniq @$input_lines;
    throw exception('InputError', 'Need at least 2 variants for pairwise LD calculation') if (scalar @input_variants < 2);
    throw exception('InputError', 'List exceeds number of allowed variants (20) for pairwise LD calculation') if (scalar @input_variants > 20);
    foreach my $name (@populations) {
      my $population = $adaptor->fetch_by_name($name);
      my $population_id = $population->dbID;
      $result_headers->{$population_id} = "Population <em>$name</em>";
      push @output_file_names, $population_id;
    }  
  } 
  elsif ($hub->param('ld_calculation') eq 'center') {
    my $variation_adaptor = $self->hub->get_adaptor('get_VariationAdaptor', 'variation', $species);
    my $manhattan_plot_input = {};
    foreach my $name (@populations) {
      my $population = $adaptor->fetch_by_name($name);
      my $population_id = $population->dbID;
      my @input_variants = uniq @$input_lines;
      foreach my $variant_name (@input_variants) {
        my $variation = $variation_adaptor->fetch_by_name($variant_name);
        if (!$variation) {
          throw exception('InputError', "Could not fetch variation for input $variant_name and species $species") if (!$variation);
        } 
        my @vfs = @{$variation->get_all_VariationFeatures};
        next if (scalar @vfs == 0);
        my $vf = $vfs[0];
        $result_headers->{"$population_id\_$variant_name"} = "population <em>$name</em> and variant: <em>$variant_name</em>";
        push @output_file_names, "$population_id\_$variant_name";
        $manhattan_plot_input->{$variant_name} = {
          'pop1' => $population_id,
          'v' => $variant_name, 
          'vf' => $vf->dbID,
        };
      }
    }  
    $job_data->{'manhattan_plot_input'} = $manhattan_plot_input;
  }
  else {
    throw exception('InputError', "Unknown ld calculation. Neither region, pairwise or center");
  }

  $job_data->{'output_file_names'} = \@output_file_names;
  $job_data->{'joined_output_file_name'} = $joined_output_file_name;
  $job_data->{'result_headers'} = $result_headers;
  $job_data->{'species'}    = $species;
  $job_data->{'input_file'} = $file_name;

  $self->add_job(EnsEMBL::Web::Job::LD->new($self, {
    'job_desc'    => $description,
    'species'     => $species,
    'assembly'    => $hub->species_defs->get_config($species, 'ASSEMBLY_VERSION'),
    'job_data'    => $job_data
  }, {
    $file_name    => {'content' => $file_content}
  }));
}

sub parse_input {
  my $input = shift;
  my @input_lines = ();
  foreach my $input_line (split/\R/, $input) {
    $input_line =~ s/^\s+|\s+$//g;
    push @input_lines, $input_line;
  }
  return \@input_lines;
}


1;
