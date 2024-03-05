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

package EnsEMBL::Web::Component::Tools::VEP::TicketDetails;

use strict;
use warnings;

use parent qw(
  EnsEMBL::Web::Component::Tools::VEP
  EnsEMBL::Web::Component::Tools::TicketDetails
);

sub job_details_table {
  ## @override
  my ($self, $job, $is_owned_ticket) = @_;

  # get basic table from superclass method
  my $two_col = $self->SUPER::job_details_table($job, $is_owned_ticket);
  my $opt_two_col = $self->new_twocol({striped => 1});

  # custom css class
  $opt_two_col->set_attribute('class', 'vep-job');

  # fetch job data and input form field information
  my $job_data = $job->job_data;
  my $form_data = $self->object->get_form_details;

  # special case frequency data, we don't want a separate line for each form element
  if($job_data->{frequency} && $job_data->{frequency} ne 'no') {
    my @tmp;

    foreach my $freq_key(qw(freq_filter freq_gt_lt freq_freq freq_pop)) {
      my %values = map { $_->{value} => $_->{caption} } grep {ref($_) eq 'HASH'} @{$form_data->{$freq_key}->{values} || []};
      push @tmp, $values{$job_data->{$freq_key}} || $job_data->{$freq_key};
    }

    $job_data->{frequency} = join(' ', @tmp);
  }
  delete $job_data->{$_} for qw(freq_filter freq_gt_lt freq_freq freq_pop);

  my (%skip, $have_plugins);

  # sort by label so at least it appears somewhat logical to user
  OPT_KEY: foreach my $opt_key(sort {
    lc($form_data->{$a} && $form_data->{$a}->{label} ? $form_data->{$a}->{label} : $a)
    cmp
    lc($form_data->{$b} && $form_data->{$b}->{label} ? $form_data->{$b}->{label} : $b)
  } keys %$job_data) {

    # we might need to remove a species suffix
    my $opt_key_lookup = $opt_key;
    $opt_key_lookup =~ s/(regulatory|cell_type)_(.+)/$1/;
    next if $2 and $2 ne $job_data->{species};

    my $opt_data = $form_data->{$opt_key_lookup};
    next unless $opt_data;

    # skip af fields if check_existing disabled
    next if $opt_key =~ /^af($|_[a-z]+$)|pubmed/ && $job_data->{check_existing} eq 'no';

    # skip disabled plugins
    if($opt_key =~ /^plugin\_/ && $job_data->{$opt_key} eq 'no') {
      $skip{$opt_key} = 1;
      next;
    }
    foreach my $sk(keys %skip) {
      next OPT_KEY if $opt_key =~ /^$sk/;
    }

    $have_plugins = 1 if $opt_key =~ /^plugin/;

    # get value labels from form details hash
    my %values = map { $_->{value} => $_->{caption} } grep {ref($_) eq 'HASH'} @{$opt_data->{values} || []};
    $values{yes} = 'Enabled';
    $values{no}  = 'Disabled';

    # process value
    my $value = $job_data->{$opt_key};
    $value = join(', ', @$value) if ref($value) eq 'ARRAY';

    # plugin checkboxes have a value the same as the key
    $value = 'Enabled' if $value eq $opt_key;

    # process label
    my $label = $opt_data->{label} || $opt_key;
    $label =~ s/\f/\&shy;/g;

    $opt_two_col->add_row(
      sprintf(
        '<p><span %s>%s%s:</span></p>',
        $opt_data->{helptip} ? 'class="ht _ht" title="'.$opt_data->{helptip}.'"' : '',
        $label,
        $opt_key =~ /^plugin/ ? '<sup style="color:grey">(p)</sup>' : '',
      ),

      $values{$value} || $value
    );
  }

  $two_col->add_row(
    'Options summary',
    $opt_two_col->render.($have_plugins ? '<p class="small"><sup style="color:grey">(p)</sup> = functionality from <a target="_blank" href="/info/docs/tools/vep/script/vep_plugins.html">VEP plugin</a></p>' : '')
  );

  ## add table with VEP data versions
  my $version_table = $self->new_twocol({striped => 1});
  $version_table->set_attribute('class', 'vep-job');

  my %version_info = $self->vep_data_version;
  # sort keys in case-insensitive order
  my @keys = sort {uc($a) cmp uc($b)} keys %version_info;
  for my $key (@keys) {
    my $value = $version_info{$key};
    if ($key eq 'db') {
      # remove internal database name
      $value =~ s/@.*//g;
      $key = 'database';
    } elsif ($key eq 'cache') {
      # strip internal path
      $value =~ s|(/[\w-]+?)+/||g;
    } elsif ($key =~ 'sift|gencode') {
      $key = uc $key;
    }
    $key = ucfirst $key unless $key =~ /[A-Z]/;
    $version_table->add_row($key, $value);
  }
  $two_col->add_row('VEP and data version', $version_table->render);

  ## create command line that users can cut and paste
  my $command_string = './vep';

  my $config = $job->dispatcher_data->{config};

  my %skip_opts = map {$_ => 1} qw(format stats_file input_file output_file);

  for my $opt(grep { !$skip_opts{$_} && defined $config->{$_} && $config->{$_} ne 'no' } sort keys %$config) {

    foreach my $value(ref($config->{$opt}) eq 'ARRAY' ? @{$config->{$opt}} : ($config->{$opt})) {

      $command_string .= ' --'.$opt;

      unless($value eq 'yes') {

        # get rid of any internal paths
        $value =~ s/(\/[\w-]+?)+\//\[path_to\]\//g;
        $command_string .= ' '.$value;
      }
    }
  }

  $command_string .= ' --cache --input_file [input_data] --output_file [output_file]';
  $command_string .= ' --port 3337' if ($job->assembly eq 'GRCh37');

  $two_col->add_row(
    '<span class="ht _ht" title="Copy and paste this to use it as a starting point for running this job on your command line">Command line equivalent</span>',
    '<pre class="code" style="height: 30px">'.$command_string.'</pre>'
  );

  return $two_col;
}

1;
