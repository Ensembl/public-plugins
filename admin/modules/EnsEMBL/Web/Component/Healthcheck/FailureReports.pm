package EnsEMBL::Web::Component::Healthcheck::FailureReports;

### 

use strict;
use warnings;
no warnings "uninitialized";
use base qw(EnsEMBL::Web::Component::Healthcheck);
use Data::Dumper;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 1 );
}

sub caption {
  my $self = shift;
  return '';
}

sub content {
  my $self = shift;
  my $object = $self->object;
  my $species = $object->species;
  my $release = $object->release;
  my $html;

  my @dbs = @{$object->database_names};

  if (@dbs) {
    foreach my $db (@dbs) {
      $html .= qq(<h2>Failures for $db</h2>);
      my @reports = $object->reports($db);

      if (@reports) {

        $html .= qq(
<p class="space-below"><strong>Note</strong>: you can annotate multiple reports by ticking the checkboxes then
clicking on the 'Multi' button at the bottom of the table.</p>
<form id="annotation" action="/$species/Healthcheck/MultiAnnotate" method="post">
);
  
        my $table = EnsEMBL::Web::Document::SpreadSheet->new();
        $table->add_columns(
          {'key' => 'testcase', 'title' => '<span id="'.$db.'">Testcase</span>', width => '10%'},
          {'key' => 'text',     'title' => 'Text', width => '20%'},
          {'key' => 'team',     'title' => 'Team & person', width => '10%', 'align' => 'center'},
          {'key' => 'comment',  'title' => 'Comment', width => '20%'},
          {'key' => 'date',     'title' => 'Date initial failure', width => '10%'},
          {'key' => 'single',   'title' => 'Annotate', 'align' => 'center', width => '10%'},
          {'key' => 'multi',    'title' => '', 'align' => 'center', width => '10%'},
          {'key' => 'action',   'title' => 'Action', width => '10%'},
        );
        foreach my $report (@reports) {
          my $testcase = '<div class="">'.$report->testcase.'</div>';
          my $annotate = 'Add?id='.$report->id;
          my $link_text = 'Add New';
          my (@team_text, $comment, $action);
          if (my $team = $report->team_responsible) {
            push @team_text, $team;
          }
          my $annotation = $report->annotation;
          if ($annotation) {
            $annotate = 'Edit?id='.$annotation->id; #.';report_id='.$report->id;
            $link_text = 'Edit';
            $comment = $annotation->comment;
            $action = $annotation->action;
            my $user_id = $annotation->modified_by || $annotation->created_by;
            my $user;
            if ($user_id) {
              $user = EnsEMBL::Web::Data::User->new($user_id);
            }
            else {
              my $person = $annotation->person;
              if ($person && $person =~ /@/) { ## Old style - email address
                $user = EnsEMBL::Web::Data::User->find('email'=>$person);
              }
            }
            if ($user) {
              push @team_text, '<a href="mailto:'.$user->email.'" title="Email this user">'.$user->name.'</a>';
            }
          }
          $table->add_row({
            'testcase'  => $testcase,
            'text'      => $report->text,
            'team'      => join('<br />', @team_text),
            'comment'   => $comment,
            'date'      => $self->friendly_date($report->created),
            'single'    => '<a href="/'.$object->species.'/Healthcheck/Annotation/'.$annotate.'">'.$link_text.'</a>',
            'multi'     => '<input type="checkbox" name="report_id" value="'.$report->id.'" />',
            'action'    => $action,
          });
        }
        $table->add_row({'multi' => '<input type="submit" name="submit" value="Multi" />'});
        $html .= $table->render;
        $html .= "\n</form>\n";
      }
      else {
        $html .= qq(<p>No testcase failures match your display options</p>);
      }
    }
  }
  
  return $html;
}

1;
