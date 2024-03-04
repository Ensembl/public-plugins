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

package EnsEMBL::Web::Component::Tools;

use strict;
use warnings;

use parent qw(EnsEMBL::Web::Component::Shared);

sub object {
  ## @override
  ## Gets the object according to the URL 'action' instead of the 'type' param, as expected in the tools based components
  return shift->SUPER::object->get_sub_object;
}

sub mcacheable {
  return 0;
}

sub new {
  ## @constructor
  ## @override To set the correct view config
  my $self = shift->SUPER::new(@_);
  if (my $hub = $self->hub) {
    $self->{'view_config'} = $hub->get_viewconfig({component => $self->id, type => $hub->action, cache => 1});
  }
  return $self;
}

sub _init {
  ## Makes all the components in tools ajaxable but not cacheable
  ## Override this in a child class to modify the default behaviour
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(1);
}

sub result_url {
  ## Get the url for the result page for a job
  ## @param Ticket object
  ## @param Job object
  my ($self, $ticket, $job) = @_;

  return {
    'species'     => $job->species,
    'type'        => 'Tools',
    'action'      => $ticket->ticket_type_name,
    'function'    => 'Results',
    'tl'          => $self->object->create_url_param({'ticket_name' => $ticket->ticket_name, 'job_id' => $job->job_id})
  };
}

sub format_date {
  ## Formats datetime from db into a printable form
  ## @param Datetime value
  ## @return String
  my ($self, $datetime) = @_;

  my @date = split /-|T|:/, $datetime;

  return sprintf '%s/%s/%s, %s:%s', $date[2], $date[1], $date[0], $date[3], $date[4];
}

1;
