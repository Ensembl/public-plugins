package EnsEMBL::Web::Component::Tools::Blast::Karyotype;

use strict;
use warnings;

use base qw(EnsEMBL::Web::Component::Tools::Blast);

sub content {
  my $self      = shift;
  my $hub       = $self->hub;
  my $object    = $self->object;
  my $sd        = $hub->species_defs;
  my $job       = $object->get_requested_job({'with_all_results' => 1});
  my $results   = $job && $job->status eq 'done' ? $job->result : [];
  my $html      = '';

  if (@$results) {

    my $job_data    = $job->job_data;
    my $species     = $job_data->{'species'};
    my $chromosomes = $sd->get_config($species, 'ENSEMBL_CHROMOSOMES') || [];

    if (@$chromosomes && $sd->MAX_CHR_LENGTH) {
      my $image_config  = $hub->get_imageconfig('Vkaryoblast');
      my $image         = $self->new_karyotype_image($image_config);
      my $pointers      = $self->get_hit_pointers($job_data, $results, $image);

      $image->set_button('drag', 'title' => 'Click on a chromosome');
      $image->imagemap  = 'yes';
      $image->karyotype($hub, $object, $pointers, 'Vkaryoblast');

      $html             = sprintf('
        <h3><a rel ="_blast_karyotype" class="toggle set_cookie open" href="#">HSP distribution on genome:</a></h3>
        <div class="_blast_karyotype">
          <div class="toggleable">%s</div>
        </div>',
        $image->render
      );
    }
  }

  return $html;
}

sub get_hit_pointers {
  my ($self, $job_data, $results, $image) = @_;

  my $object        = $self->object;
  my $hub           = $self->hub;
  my $species       = $job_data->{'species'};
  my $pointer_style = $self->blast_pointer_style;

  my @features      = map {
    my $hit_id        = $_->result_id;
    my $hit           = $_->result_data;
    {
      'region'          => $hit->{'gid'},
      'start'           => $hit->{'gstart'},
      'end'             => $hit->{'gend'},
      'p_value'         => 1 + $hit->{'pident'} / 100,
      'strand'          => $hit->{'gori'},
      'label'           => 'Test', #TODO
      'href'            => $hub->url({
        'species'         => $species,
        'type'            => 'ZMenu',
        'action'          => 'Blast',
        'function'        => '',
        'tl'              => $object->create_url_param({'result_id' => $hit_id}),
      }),
      'html_id'         => "hsp_$hit_id"
    }
  } @$results;

  return [ $image->add_pointers($hub, {
    config_name   => 'Vkaryoblast',
    features      => \@features,
    feature_type  => 'Xref',
    style         => $pointer_style->{'style'},
    color         => $pointer_style->{'colour'},
    gradient      => $pointer_style->{'gradient'},
  }) ];
}

1;
