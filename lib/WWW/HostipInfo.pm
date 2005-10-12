package WWW::HostipInfo;

use strict;
use LWP::UserAgent;
use Carp;
use vars qw($VERSION);

$VERSION = 0.05;

my $Hostip_info = 'http://www.hostip.info/api/get.html?position=true&ip=';

sub new {
	my $class = shift;
	my $ip    = shift;
	my $self  = {};

	bless $self, $class;
	$self->_init();
	$self->ip($ip) if(defined $ip);
	$self;
}


sub _init {
	my $self = shift;
	$self->{_ua} = LWP::UserAgent->new(agent => "WWW::HostipInfo/$VERSION");
}


sub ua { $_[0]->{_ua} }


sub recent_info { $_[0]->{_recent_info}; }


sub ip {
	$_[0]->{_ip} = $_[1] if(@_ > 1);
	$_[0]->{_ip}
}


sub get_info {
	my $self = shift;
	my $ip   = shift || $self->ip;

	if(!defined $ip or $ip eq ''){ croak "IP address is required."  }
	$self->ip($ip);

	my $response  = $self->ua->get($Hostip_info . $ip);
	return unless($response->is_success);

	my $content = $response->content;
	my ($country, $city, $lat, $lon) = (split/\n/,$content);
	my ($name, $code) = $country =~ /^Country: (.+?)\s*\((\w\w)\)$/;
	my $region;

	($lat) = $lat =~ /^Latitude: (.+)$/;
	($lon) = $lon =~ /^Longitude: (.+)$/;
	($city, $region) = $city =~ /^City: ([^,]+)(?:, (\w+))?$/;

	if($city eq '(Unknown city)'){ $city = ''; $region = ''; }

	$self->{_recent_info} = bless {
		_CountryName => $name,
		_CountryCode => $code,
		_City        => $city,
		_Region      => ($region || ''),
		_Latitude    => $lat,
		_Longitude   => $lon,
	}, 'WWW::HostipInfo::Info';
}



package WWW::HostipInfo::Info;

sub name { $_[0]->{_CountryName}; }

sub code { $_[0]->{_CountryCode}; }

sub country_name { $_[0]->{_CountryName}; }

sub country_code { $_[0]->{_CountryCode}; }

sub city { $_[0]->{_City}; }

sub region { $_[0]->{_Region}; }

sub latitude { $_[0]->{_Latitude}; }

sub longitude { $_[0]->{_Longitude} }


1;
__END__

=pod

=head1 NAME

WWW::HostipInfo - get a country and city information from ip address.


=head1 SYNOPSIS

 use WWW::HostipInfo;

 my $hostip = new WWW::HostipInfo;
 my $ip     = 'xxx.xxx.xxx.xxx';
 my $info   = $hostip->get_info($ip);
 
 my $country_code = $info->code;
 my $city_name    = $info->city;
 my $region       = $info->region; # if any
 
 $info = $hostip->recent_info->country_name; # fetch most recent data
 
 print WWW::HostipInfo->new($ip)->get_info->city; # shortcut


=head1 DESCRIPTION

This module gets a country and city information via hostip.info.


=head1 METHODS

=over 4

=item new

returns a WWW::HostipInfo object.
This method can take ip address optionally.

=item ip

setter / getter to ip address.

=item get_info

returns a WWW::HostipInfo::Info object.
If the method can't get a information, will return C<undef>.

=item recent_info

returns a WWW::HostipInfo::Info object.

=back



=head1 WWW::HostipInfo::Info

With C<get_info()>, WWW::HostipInfo object returns
WWW::HostipInfo::Info object.

=head2 METHODS

getters for informations.

=over 4

=item country_code

return the cuntry code.

=item code

an alias to country_code

=item country_name

return the cuntry name.

=item name

an alias to country_name

=item city

return the city name as long as it is not unknown.

=item region

return state code if the coutnry is US.

=item latitude

=item longitude

=back

=head1 SEE ALSO

L<http://www.hostip.info/>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is licensed under GNU GENERAL PUBLIC LICENSE

=cut

