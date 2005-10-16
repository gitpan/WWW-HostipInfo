##############################################################################
package WWW::HostipInfo;

use strict;
use LWP::UserAgent;
use Carp;
use vars qw($VERSION $DEBUG);

$VERSION = 0.08;

my $GetAPI   = 'http://www.hostip.info/api/get.html?position=true&ip=';
my $RoughAPI = 'http://www.hostip.info/api/rough.html?position=true&ip=';


## PUBLIC METHOD

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
	my $opt  = shift || {};

	my $chk = $self->_check_ipaddr($ip);
	# $chk : 0..invalid ip address, 1..class A - C, 2..class D or E, 3..private
	if(!$chk){
		croak "IP address is required."
	}
	elsif($chk == 2){
		return $self->_get_info_as_null;
	}
	elsif($chk == 3){
		return $self->_get_info_as_private
	}

	$self->ip($ip);

	my $url       = $opt->{Guess} ? $RoughAPI : $GetAPI;
	my $response  = $self->ua->get($url . $ip);

	return unless($response->is_success);

	my $content = $response->content;
	_convert_content(\$content) unless($opt->{Guess});
	if($DEBUG){ warn $content; }

	return $self->_set_info_to_obj($content);
}


sub guess {
	my ($self, $ip) = @_;
	$ip = $self->recent_info->ip if(@_ < 2 and $self->recent_info);
	$self->get_info( $ip, {Guess => 1} );
}



## PRIVATE METHOD

sub _check_ipaddr {
	return 0 if(!defined $_[1] or $_[1] !~ /^(\d{1,3})\.(\d{1,3})\.\d{1,3}\.\d{1,3}$/);
	return 2 if($1 >= 224); # class D or E
	return   ($1 == 127 or $1 == 10)   ? 3
	       : ($1 == 192 and $2 == 168) ? 3
	       : ($1 == 172 and $2 >= 16 and $2 <= 31) ? 3 : 1;
}


sub _convert_content { # make a content format same as /api/rough.html.
	my $ref = $_[0];
	$$ref =~ s{Country: (.+?)\s*\((\w\w)\)}{Country: $1\nCountry Code: $2}s;
}


sub _set_info_to_obj {
	my ($self, $content) = @_;
	my ($name, $code, $city, $lat, $lon, $guess) = (split/\n/,$content);
	my $region;

	($name) = $name =~ /^Country: (.+?)$/;
	($code) = $code =~ /^Country Code: (\w\w)$/;
	($lat)  = $lat =~ /^Latitude: (.+)$/;
	($lon)  = $lon =~ /^Longitude: (.+)$/;
	($city, $region) = $city =~ /^City: ([^,]+)(?:, (\w+))?$/;

	my ($unknown_city, $unknown_country) = (0,0);
	if($city =~ /^\([uU]nknown [cC]ity/){
		$city = ''; $region = ''; $unknown_city = 1;
	}
	if($name =~ /^\([uU]nknown [cC]ountry/){
		$name = ''; $unknown_country = 1;
	}

	$self->{_recent_info} = bless {
		_ipaddr      => $self->ip,
		_CountryName => $name,
		_CountryCode => $code,
		_City        => $city,
		_Region      => ($region || ''),
		_Latitude    => $lat,
		_Longitude   => $lon,
		_private     => 0,
		_un_city     => $unknown_city,
		_un_country  => $unknown_country,
		_guessed     => ($guess ? 1 : 0),
	}, 'WWW::HostipInfo::Info';
}


sub _get_info_as_null {
	$_[0]->{_recent_info} = bless {
		_ipaddr      => $_[0]->ip,
		_CountryName => '',
		_CountryCode => 'XX',
		_City        => '',
		_Region      => undef,
		_Latitude    => undef,
		_Longitude   => undef,
		_private     => 0,
		_un_city     => 1,
		_un_country  => 1,
		_guessed     => 0,
	}, 'WWW::HostipInfo::Info';
}


sub _get_info_as_private {
	$_[0]->{_recent_info} = bless {
		_ipaddr      => $_[0]->ip,
		_CountryName => '',
		_CountryCode => 'XX',
		_City        => '',
		_Region      => undef,
		_Latitude    => undef,
		_Longitude   => undef,
		_private     => 1,
		_un_city     => 1,
		_un_country  => 1,
		_guessed     => 0,
	}, 'WWW::HostipInfo::Info';
}


##############################################################################
# Information Class
##############################################################################

package WWW::HostipInfo::Info;

sub is_private { $_[0]->{_private}; }

sub is_guessed { $_[0]->{_guessed}; }

sub has_unknown_city { $_[0]->{_un_city}; }

sub has_unknown_country { $_[0]->{_un_country}; }

sub ip { $_[0]->{_ipaddr}; }

sub name { $_[0]->{_CountryName}; }

sub code { $_[0]->{_CountryCode}; }

sub country_name { $_[0]->{_CountryName}; }

sub country_code { $_[0]->{_CountryCode}; }

sub country { $_[0]->{_CountryName}; }

sub city { $_[0]->{_City}; }

sub region { $_[0]->{_Region}; }

sub latitude { $_[0]->{_Latitude}; }

sub longitude { $_[0]->{_Longitude} }

##############################################################################
1;
__END__

=pod

=head1 NAME

WWW::HostipInfo
 - get a country and city information from ip address via www.hostip.info API.


=head1 SYNOPSIS

 use WWW::HostipInfo;

 my $hostip = new WWW::HostipInfo;
 my $ip     = 'xxx.xxx.xxx.xxx';
 my $info   = $hostip->get_info($ip);
 
 if($info->is_private){ warn "This is a private ip address." }
 
 my $country_code = $info->code;
 my $city_name    = $info->city;
 my $region       = $info->region; # if any
 
 $info = $hostip->recent_info->country_name; # fetch most recent data
 
 print WWW::HostipInfo->new($ip)->get_info->city; # shortcut
 
 $info = $hostip->guess($info->ip) if( $info->has_unknown_city );


=head1 DESCRIPTION

This module gets a country and city information from ip address
via L<www.hostip.info> API.


=head1 METHODS

=over 4

=item new

returns a WWW::HostipInfo object.
This method can take ip address optionally.


=item ip([$ip])

setter / getter to ip address.


=item get_info

returns a WWW::HostipInfo::Info object.
If the method can't get a information, will return C<undef>.


=item guess([$ip])

returns a WWW::HostipInfo object.
If the original city is unknown, returns a guessed infomation.
When the argument was not set, most recent data is used.


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
If private ip address is used, the code is 'XX'.

=item code

an alias to country_code


=item country_name

return the cuntry name.

=item name

an alias to country_name

=item country

an alias to country_name

=item city

return the city name as long as it is not unknown.


=item region

return state code if the coutnry is US.


=item latitude


=item longitude


=item ip


=item is_private

If private ip address is used, returns true.

=item is_guessed

If the object has any guessed data, returns true.

=item has_unknown_city

If the object has no data for city, returns true.

=item has_unknown_country

If the object has no data for country, returns true.


=back

=head1 SEE ALSO

L<http://www.hostip.info/>,
L<LWP>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is licensed under GNU GENERAL PUBLIC LICENSE

=cut

