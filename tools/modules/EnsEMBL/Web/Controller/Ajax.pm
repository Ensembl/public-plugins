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

package EnsEMBL::Web::Controller::Ajax;

use strict;
use warnings;

use JSON qw(to_json);
use EnsEMBL::Web::Utils::DynamicLoader qw(dynamic_require);

sub ajax_tools_tab {
  my ($self, $hub) = @_;

  my $response  = {'empty' => 1};
  my $sd        = $hub->species_defs;
  my $user      = $hub->user;
  my $manager   = $hub->tools_available && dynamic_require('ORM::EnsEMBL::DB::Tools::Manager::Ticket', 1);
  my $count     = $manager && $manager->count_current_tickets({
    'site_type'   => $sd->tools_sitetype,
    'session_id'  => $hub->session->session_id, $user ? (
    'user_id'     => $user->user_id ) : ()
  });

  if ($manager && $count) {

    my $object  = $self->new_object('Tools', undef, {'_hub' => $hub});
    my @recent  = keys %{{ map {$_ => 1} split(',', $hub->param('recent') || '') }};
    my @tools   = $sd->tools_list;
    my @jobs;

    # tab caption and action
    $response->{'caption'}  = $object->ajax_short_caption;
    $response->{'url'}      = $hub->url({'type' => 'Tools', 'action' => $object->ajax_default_action});

    # links for all tools inside the dropdown
    while (my ($key, $caption) = splice @tools, 0, 2) {
      $response->{'tools'}{$key} = {
        'caption' => $caption,
        'url'     => $hub->url({'type' => 'Tools', 'action' => $key, 'function' => '', '__clear' => 1}),
        'jobs'    => []
      };
    }

    # recent jobs for the current species
    for (@recent) {
      my ($ticket_name, $job_id) = split /-/, $_;
      next unless $job_id;
      push @jobs, {
        'url_param'   => "$ticket_name-$job_id",
        'ticket_name' => $ticket_name,
        'job_id'      => $job_id
      };
    }

    if (@jobs) {

      my $recent_tickets = $manager->get_objects('query' => ['ticket_name' => [ map $_->{'ticket_name'}, @jobs ]]);

      # link tickets and keep only the 'done' jobs
      foreach my $job (@jobs) {
        for (@$recent_tickets) {
          if ($_->ticket_name eq $job->{'ticket_name'}) {
            my $job_rose_object = $_->find_job('query' => [ 'job_id' => $job->{'job_id'} ])->[0];
            if ($job_rose_object && $job_rose_object->status eq 'done') {
              $job->{'ticket_type'} = $_->ticket_type_name;
              $job->{'species'}     = $job_rose_object->species;
              $job->{'job_desc'}    = $job_rose_object->job_desc;
            }
          }
        }
      }

      @jobs = grep $_->{'species'}, @jobs; # filter out all the jobs they are not 'done' yet

      # add jobs to response
      for (@jobs) {

        push @{$response->{'tools'}{$_->{'ticket_type'}}{'jobs'}}, {
          'caption' => sprintf('%s: %s', $sd->get_config($_->{'species'}, 'SPECIES_DISPLAY_NAME'), $_->{'job_desc'}),
          'url'     => $hub->url({
            '__clear'   => 1,
            'species'   => $_->{'species'},
            'type'      => 'Tools',
            'action'    => $_->{'ticket_type'},
            'function'  => 'Results',
            'tl'        => $_->{'url_param'}
          })
        };
      }
    }

    delete $response->{'empty'};
  }

  print to_json($response);
}

1;
