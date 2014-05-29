=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Document::Element::Tabs;

# Adds Tools tab to the existing tabs

use strict;
use warnings;

use previous qw(init dropdown);

use ORM::EnsEMBL::DB::Tools::Manager::Ticket;
use EnsEMBL::Web::DOM;

sub init {
  my $self        = shift;
  my $controller  = $_[0];
  my $hub         = $controller->hub;
  my $user        = $hub->user;

  $self->PREV::init(@_);

  # if tools tab is already there because of the tl param, force dropdown
  if (my ($tools_tab) = grep {($_->{'type'} || '') eq 'Tools'} @{$self->entries}) {
    $tools_tab->{'dropdown'} = 'tools';

  } else {

    # if tl param is not present, but the user has some tickets, add tools tab now
    if (ORM::EnsEMBL::DB::Tools::Manager::Ticket->count_current_tickets({
      'site_type'   => $hub->species_defs->ENSEMBL_SITETYPE,
      'session_id'  => $hub->session->create_session_id, $user ? (
      'user_id'     => $user->user_id ) : ()
    })) {

      $self->add_entry({
        'type'      => 'Tools',
        'caption'   => 'Jobs',
        'url'       => $hub->url({qw(type Tools action Summary __clear 1)}),
        'class'     => 'tools',
        'dropdown'  => 'tools'
      });
    }
  }
}

sub dropdown {
  ## we override this to display a custom dropdown for tools
  my $self      = shift;
  my $hub       = $self->hub;
  my $sd        = $hub->species_defs;
  my $dropdowns = $self->PREV::dropdown(@_);
  my $div       = EnsEMBL::Web::DOM->new->create_element('div', {'class' => 'dropdown tools', 'children' => [{'node_name' => 'h4', 'inner_HTML' => 'Recent jobs'}, {'node_name' => 'ul'}]});
  my @jobs;

  while (($dropdowns->{'tools'} || '') =~ m/(\?|;|\&)tl\=([a-z0-9\-_]+)/ig) {
    my ($ticket_name, $job_id) = split /-/, "$2-";
    push @jobs, {
      'url_param'   => "$ticket_name-$job_id",
      'ticket_name' => $ticket_name,
      'job_id'      => $job_id
    };
  }

  my $tools_divs = {};
  my @tool_types = @{$sd->ENSEMBL_TOOLS_LIST};

  for (@tool_types) {
    while (my ($key, $caption) = splice @tool_types, 0, 2) {
      $tools_divs->{$key} = $div->last_child->append_child({
        'node_name' => 'li',
        'children'  => [{'node_name' => 'a', 'href' => $hub->url({'type' => 'Tools', 'action' => $key, 'function' => '', '__clear' => 1}), 'inner_HTML' => $caption}]
      });
    }
  }

  if (@jobs) {

    my $recent_tickets = ORM::EnsEMBL::DB::Tools::Manager::Ticket->get_objects('query' => ['ticket_name' => [ keys %{{ map { $_->{'ticket_name'} => 1 } @jobs }} ]]);

    foreach my $job (@jobs) {
      for (@$recent_tickets) {
        if ($_->ticket_name eq $job->{'ticket_name'}) {
          my $job_rose_object = shift @{$_->find_job('query' => [ 'job_id' => $job->{'job_id'} ])};
          if ($job_rose_object && $job_rose_object->status eq 'done') {
            $job->{'ticket_type'} = $_->ticket_type_name;
            $job->{'species'}     = $job_rose_object->species;
          }
        }
      }
    }

    if (@jobs = sort {$a->{'ticket_type'} cmp $b->{'ticket_type'}} grep { $_->{'species'} } @jobs) {

      my $ticket_type = '';
      my $duplicates  = {};

      for (@jobs) {

        next if $duplicates->{$_->{'url_param'}};
        $duplicates->{$_->{'url_param'}} = 1;

        if ($_->{'ticket_type'} ne $ticket_type) {
          $ticket_type  = $_->{'ticket_type'};
          $tools_divs->{$ticket_type}->append_child('ul', {'class' => 'recent'}) unless $tools_divs->{$ticket_type}->last_child->node_name eq 'ul';
        }
        $tools_divs->{$ticket_type}->last_child->append_child('li', {'inner_HTML' => sprintf('<a href="%s" class="constant tools">%s: %s</a>', $hub->url({
          '__clear'   => 1,
          'species'   => $_->{'species'},
          'type'      => 'Tools',
          'action'    => $ticket_type,
          'function'  => 'Results',
          'tl' => $_->{'url_param'}
        }), $sd->get_config($_->{'species'}, 'SPECIES_COMMON_NAME'), $_->{'ticket_name'})});
      }

      $div->last_child->append_child('li', {
        'inner_HTML' => sprintf('<a href="%s" class="constant clear_history bold">Clear history</a>', $hub->url({qw(type Account action ClearHistory object Tools)}))
      });
    }
  }

  $dropdowns->{'tools'} = $div->render;

  return $dropdowns;
}

1;
