# --
# Copyright (C) 2014 - 2016 Perl-Services.de, http://www.perl-services.de/
# Copyright (C) 2023 mo-azfar,https://github.com/mo-azfar
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ShowQueueServiceComment;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject = $Kernel::OM->Get('Kernel::System::Web::Request');
   
	my $Action = $ParamObject->GetParam( Param => 'Action' );
	
	return 1 if !$Action;
    return 1 if !$Param{Templates}->{$Action};
    
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Param{QueueComment} )
    {
        my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
        my %QueueList = $QueueObject->GetAllQueues( UserID => $Self->{UserID}, Type => 'create' );

        my $AllQueues;
        foreach my $QueueID ( keys %QueueList )
        {
            my %QueueAtt = $QueueObject->QueueGet(
                ID    => $QueueID,
            );

            next if !$QueueAtt{Comment};
            my $PossibleQueue = "$QueueID||$QueueAtt{Name}";
            $AllQueues->{$PossibleQueue} =  $QueueAtt{Comment};
        }
        
        my $QueueCommentJSON = $JSONObject->Encode( Data => $AllQueues );

        $LayoutObject->AddJSOnDocumentComplete(
                Code => qq~
                let queue_comments = $QueueCommentJSON;
                \$('#Dest').bind('change', function() {                  
                    let queue_comment = queue_comments[\$(this).val()] || '';

                    \$("label[for='Dest']").attr("id", "DestComment"); 
                    let labelElement = document.getElementById("DestComment");
                    labelElement.innerHTML = "To queue: " + "(" + queue_comment + ")";   
                });
            ~,
        );
        
    }
    
    if ( $Param{ServiceComment} )
    {
        my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');

        my $ServiceList = $ServiceObject->ServiceListGet(
            Valid  => 1,   # (optional) default 1 (0|1)
            UserID => 1,
        );

        my $AllServices;
        foreach my $Service ( @{$ServiceList} )
        {
           next if !$Service->{Comment};
           $AllServices->{$Service->{ServiceID}} =  $Service->{Comment};
        }
        
        my $ServiceCommentJSON = $JSONObject->Encode( Data => $AllServices );

        $LayoutObject->AddJSOnDocumentComplete(
                Code => qq~
                let service_comments = $ServiceCommentJSON;
                \$('#ServiceID').bind('change', function() {
                    let service_comment = service_comments[\$(this).val()] || '';

                    \$("label[for='ServiceID']").attr("id", "ServiceComment"); 
                    let labelElement = document.getElementById("ServiceComment");
                    labelElement.innerHTML = "Service: " + "(" + service_comment + ")";     
                });
            ~,
        );
    }
	
    return 1;
}

1;
