package EnsEMBL::Web::Component::Tools::Blast;

### Base class for all Blast components

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;

use base qw(EnsEMBL::Web::Component::Tools);

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Extra param hashref as required by expand_job_status method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $params) = @_;

  my $object    = $self->object;
  my $job_data  = $job->job_data;

  return $self->new_twocol(
    ['Search type'    => $object->get_param_value_caption('search_type', $job_data->{'search_type'})],
    ['Sequence'       => sprintf('<pre>&gt;%s</pre>', join("\n", $job_data->{'sequence'}{'display_id'} || '', ($job_data->{'sequence'}{'seq'} =~ /.{1,60}/g)))],
    ['Query type'     => $object->get_param_value_caption('query_type', $job_data->{'query_type'})],
    ['DB type'        => $object->get_param_value_caption('db_type', $job_data->{'db_type'})],
    ['Source'         => $object->get_param_value_caption('source', $job_data->{'source'})],
    ['Description'    => $job->job_desc // '-'],
    ['Configurations' => $self->new_twocol(
      ['TODO', '-']
    )->render],
    ['Status'         => $self->expand_job_status($job, $params)->render]
  );
}

sub blast_pointer_style {
  ## Pointer style for blast result page images
  return {
    'style'     => 'rharrow',
    'colour'    => 'gradient',
    'gradient'  => [qw(10 gold orange chocolate firebrick darkred)]
  };
}

sub no_result_hit_found {
  ## Default HTML to be displayed if no hit was found according to the URL params
  return 'No Hit was found according to your request.';# TODO - display button to go back to summary page
}


##########


### - TODO
sub get_download_link {
  my ($self, $ticket, $format, $filename) = @_;
  my $hub = $self->hub;

  my $url = $hub->url({
    'type'    => 'Tools',
    'format'  => $format,
    'action'  => 'Download',
    'tk'      => $ticket,
    'file'    => $filename,
    '_format' => 'Text'
  });

  return $url;  
}

1;
