package EnsEMBL::Admin::Component::Healthcheck::Annotation;

use strict;

use base qw(EnsEMBL::Admin::Component::Healthcheck);

sub caption {
  return 'Annotation';
}

sub content {
  my $self = shift;
  
  my $object  = $self->object;
  my $reports = $object->rose_objects;
  my $referer = $self->hub->referer->{'uri'};
  my $user    = $self->hub->user;

  return '<p class="hc_p">No report found to annotate. (Missing report id)</p>' unless $reports && @$reports;

  my $heading       = 'Add annotation';
  my $label_done_by = 'Added by';
  my $comment       = {
    'text'        => '',
    'action'      => '',
    'created_by'  => '',
  };
  
  my $annotation;
  if (scalar @$reports == 1 && ($annotation = $reports->[0]->annotation)) {
    my $created_by_user       = $annotation->created_by_user;
    $comment->{'text'}        = $annotation->comment;
    $comment->{'action'}      = $annotation->action;
    $comment->{'created_by'}  = $created_by_user->name if $created_by_user;
    $heading                  = 'Edit annotation';
    $label_done_by            = 'Edited by';
  }

  my $html = sprintf('<h4>Report%s</h4><ul>', scalar @$reports > 1 ? 's' : '');
  my $rid  = []; #ArrayRef of report ids to be passed as POST param
  
  for (@$reports) {
    next unless $_->report_id;
    $html .= sprintf('<li><b>%s (%s)</b>: %s</li>', $_->database_name, $_->testcase, join (', ', split (/,\s?/, $_->text)));
    push @$rid, $_->report_id;
  }
  $html   .= '</ul>';
  
  my $form = $self->new_form({'id' => 'annotation', 'action' => '/Healthcheck/AnnotationSave'});
  
  $form->add_fieldset($heading);
  
  my $options = []; #options for action select box
  my $actions = $self->annotation_action('all');
  push @$options, {'value' => $_, 'caption' => $actions->{$_}} for keys %$actions;
  
  $form->add_field([{
    'label'     => 'Action',
    'name'      => 'action',
    'value'     => $self->annotation_action($comment->{'action'})->{'value'},
    'type'      => 'DropDown',
    'select'    => 'select',
    'values'    => $options
  },{
    'label'     => 'Comment',
    'type'      => 'Text',
    'name'      => 'comment',
    'value'     => $comment->{'text'}
  }]);

  $form->add_field({
    'label'     => 'Added by',
    'type'      => 'NoEdit',
    'name'      => 'added_by_name',
    'value'     => $comment->{'created_by'},
  }) if $comment->{'created_by'} ne '';

  $form->add_field({
    'label'     => $label_done_by,
    'type'      => 'NoEdit',
    'name'      => 'user_name',
    'value'     => $user->name,
  });

  $form->add_button({
    'type'      =>  'Submit',
    'value'     =>  'Save',
    'name'      =>  'submit'
  });

  $form->add_hidden([
    {'name' => 'rid',       'value' => join (',', @$rid)},
    {'name' => 'referrer',  'value' => $referer}
  ]);

  return $html.$form->render;
}

1;