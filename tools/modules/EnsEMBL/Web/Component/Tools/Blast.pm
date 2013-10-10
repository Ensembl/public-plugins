package EnsEMBL::Web::Component::Tools::Blast;

### Base class for all Blast components

use strict;
use warnings;

use EnsEMBL::Web::Exceptions;
use EnsEMBL::Web::BlastConstants qw(CONFIGURATION_FIELDS);

use base qw(EnsEMBL::Web::Component::Tools);

sub job_details_table {
  ## A two column layout displaying a job's details
  ## @param Job object
  ## @param Extra param hashref as required by expand_job_status method
  ## @return DIV node (as returned by new_twocol method)
  my ($self, $job, $params) = @_;

  my $object    = $self->object;
  my $job_data  = $job->job_data;
  my $configs   = $self->_display_config($job_data->{'configs'});
  my $two_col   = $self->new_twocol;

  $two_col->add_row('Search type',    $object->get_param_value_caption('search_type', $job_data->{'search_type'}));
  $two_col->add_row('Sequence',       sprintf('<pre>&gt;%s</pre>', join("\n", $job_data->{'sequence'}{'display_id'} || '', ($job_data->{'sequence'}{'seq'} =~ /.{1,60}/g))));
  $two_col->add_row('Query type',     $object->get_param_value_caption('query_type', $job_data->{'query_type'}));
  $two_col->add_row('DB type',        $object->get_param_value_caption('db_type', $job_data->{'db_type'}));
  $two_col->add_row('Source',         $object->get_param_value_caption('source', $job_data->{'source'}));
  $two_col->add_row('Description',    $job->job_desc // '-');
  $two_col->add_row('Configurations', $configs) if $configs;
  $two_col->add_row('Status',         $self->expand_job_status($job, $params)->render);

  return $two_col;
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
  return 'No result hit was found according to your request.';# TODO - display button to go back to summary page
}

sub _display_config {
  ## @private
  my ($self, $configs) = @_;
  my $fields  = CONFIGURATION_FIELDS;
  my $div     = $self->dom->create_element('div');

  while (my ($config_type, $config_fields) = splice @$fields, 0, 2) {

    my @rows = ({'node_name' => 'p', 'inner_HTML' => sprintf('<b>%s options</b>', ucfirst $config_type =~ s/_/ /gr)});

    while (my ($field_name, $field_details) = splice @$config_fields, 0, 2) {
      if (exists $configs->{$field_name}) {
        my ($value) = exists $field_details->{'commandline_values'}
          ? ucfirst $configs->{$field_name} # since the value for this field is set according to 'commandline_values'
          : map { $_->{'value'} eq $configs->{$field_name} ? $_->{'caption'} : () } @{$field_details->{'values'}} # otherwise choose the right 'caption' key from the 'values' arrayref that hash a matching 'value' key
        ;
        push @rows, {'node_name' => 'p', 'inner_HTML' => sprintf('%s: %s', $field_details->{'label'}, $value // '')};
      }
    }

    $div->append_children(@rows) if @rows > 1;
  }

  return $div->is_empty ? '' : $div->render;
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
