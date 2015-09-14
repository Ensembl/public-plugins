=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Tools::VEP;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Tools);

sub job_statistics {
  ## Gets the job result stats for display on results pages
  my $self    = shift;
  my $file    = $self->object->result_files->{'stats_file'};
  my $stats   = {};
  my $section;

  for (split /\n/, $file->content) {
    if (m/^\[(.+?)\]$/) {
      $section = $1;
    } elsif (m/\w+/) {
      my ($key, $value) = split "\t";
      $stats->{$section}->{$key} = $value;
      push @{$stats->{'sort'}->{$section}}, $key;
    }
  }

  return $stats;
}


sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Flag to tell whether user or session owns the ticket or not
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $is_owned_ticket) = @_;

  # get basic table from superclass method
  my $two_col = $self->SUPER::job_details_table($job, $is_owned_ticket);
  my $opt_two_col = $self->new_twocol({striped => 1});

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
  foreach my $opt_key(sort {
    lc($form_data->{$a} && $form_data->{$a}->{label} ? $form_data->{$a}->{label} : $a)
    cmp
    lc($form_data->{$b} && $form_data->{$b}->{label} ? $form_data->{$b}->{label} : $b)
  } keys %$job_data) {

    # we might need to remove a species suffix
    my $opt_key_lookup = $opt_key;
    $opt_key_lookup =~ s/(regulatory|cell_type)(_.+)/$1/;

    my $opt_data = $form_data->{$opt_key_lookup};
    next unless $opt_data;

    # skip disabled plugins
    if((grep {$_ =~ /$opt_key\_/} keys %skip) || ($opt_key =~ /^plugin\_/ && $job_data->{$opt_key} ne $opt_key)) {
      $skip{$opt_key} = 1;
      next;
    }

    $have_plugins = 1 if $opt_key =~ /^plugin/;

    # get value labels from form details hash
    my %values = map { $_->{value} => $_->{caption} } grep {ref($_) eq 'HASH'} @{$opt_data->{values} || []};
    $values{yes} = 'Enabled';
    $values{no}  = 'Disabled';

    my $label = $opt_data->{label} || $opt_key;
    $label =~ s/\f/\&shy;/g;

    $opt_two_col->add_row(
      sprintf(
        '<span %s>%s%s:</span>',
        $opt_data->{helptip} ? 'class="ht _ht" title="'.$opt_data->{helptip}.'"' : '',
        $label,
        $opt_key =~ /^plugin/ ? ' *' : '',
      ),

      # plugin checkboxes have a value the same as the key
      $values{$job_data->{$opt_key}} || ($job_data->{$opt_key} eq $opt_key ? 'Enabled' : $job_data->{$opt_key})
    );
  }

  $two_col->add_row(
    'Options summary',
    $opt_two_col->render.($have_plugins ? '<p class="small">* = functionality from <a href="/info/docs/tools/vep/script/vep_plugins.html">VEP plugin</a></p>' : '')
  );

  return $two_col;
}

1;
