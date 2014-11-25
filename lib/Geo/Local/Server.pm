package Geo::Local::Server;
use strict;
use warnings;
use base qw{Package::New};
use Config::IniFiles qw{};
use Path::Class qw{file};
#runtime use Win32 if Windows
#runtime use Sys::Config unless Windows

our $VERSION = '0.04';

=head1 NAME

Geo::Local::Server - Returns the configured coordinates of the local server

=head1 SYNOPSIS

  use Geo::Local::Server;
  my $gls=Geo::Local::Server->new;
  my ($lat, $lon)=$gls->latlon;

=head1 DESCRIPTION

Reads coordinates from either the user environment variable COORDINATES_WGS84_LON_LAT_HAE or the file /etc/local.coordinates.

=head1 USAGE

=head1 METHODS

=head2 lat

Returns the latitude.

=cut

sub lat {(shift->lonlathae)[1]};

=head2 lon

Returns the longitude

=cut

sub lon {(shift->lonlathae)[0]};

=head2 latlon, latlong

Returns a list of latitude, longitude

=cut

sub latlon {(shift->lonlathae)[1,0]};
 
sub latlong {(shift->lonlathae)[1,0]};

=head2 hae

Returns the configured height of above the ellipsoid

=cut

sub hae {(shift->lonlathae)[2]};

=head2 lonlathae

Returns a list of longitude, latitude and height of above the ellipsoid

=cut

sub lonlathae {
  my $self=shift;
  unless ($self->{"lonlathae"}) {
    my @supported=(
                   "Environment variable COORDINATES_WGS84_LON_LAT_HAE",
                   "Filesystem /etc/local.coordiantes file",
                  );
    my $coordinates="";
    if ($self->env) {
      $coordinates=$ENV{$self->env} || "";
      $coordinates=~s/^\s*//; #trim white space from beginning
      $coordinates=~s/\s*$//; #trim white space from end
    }
    if ($coordinates) {
      #First Step Pull from environment which can be configured by user
      my ($lon, $lat, $hae)=split(/\s+/, $coordinates);
      $self->{"lonlathae"}=[$lon, $lat, $hae];
    } elsif (-r $self->configfile) {
      #Second Step Pull from file system which can be configured by system
      my $lat=$self->Config->val(wgs84 => "latitude");
      my $lon=$self->Config->val(wgs84 => "longitude");
      my $hae=$self->Config->val(wgs84 => "hae");
      $self->{"lonlathae"}=[$lon, $lat, $hae];
    } else {
      #TODO: GeoIP
      #TODO: gpsd
      #TODO: some kind of memory block transfer
      die("Error: None of the following supported coordinate standards are configured.\n\n",
          join("\n", map {"    - $_"} @supported).
          "\n\n "
          );
    }
  }
  return @{$self->{"lonlathae"}};
}

=head1 PROPERTIES

=head2 env

Set and returns the name of the environment variable.

  my $var=$gls->env; #default COORDINATES_WGS84_LON_LAT_HAE
  $gls->env("");     #disable environment lookup
  $gls->env(undef);  #reset to default

=cut

sub env {
  my $self=shift;
  $self->{"env"}=shift if $_;
  $self->{"env"}="COORDINATES_WGS84_LON_LAT_HAE" unless defined $self->{"env"};
  return $self->{"env"};
}

=head2 configfile

Sets and returns the location of the local.coordinates filename.

=head3 FORMAT

The local.coordinates file is a formatted INI file. The [wgs84] section is required for this package to function.

  [main]
  version=1

  [wgs84]
  latitude=38.780276
  longitude=-77.386706
  hae=63

=cut

sub configfile {
  my $self=shift;
  $self->{"configfile"}=shift if @_;
  unless ($self->{"configfile"}) {
    my $file="local.coordinates";
    my $path="/etc"; #default is unix-like systems
    if ($^O eq "MSWin32") {
      eval("use Win32");
      $path=eval("Win32::GetFolderPath(Win32::CSIDL_WINDOWS)") unless $@;
    } else {
      eval("use Sys::Path");
      $path=eval("Sys::Path->sysconfdir") unless $@;
    }
    $self->{"configfile"}=file($path => $file); #isa Path::Class::File
  }
  return $self->{"configfile"};
}

=head1 Object Accessors

=head2 Config

Returns the L<Config::IniFiles> object so that you can read additional information from the INI file.

  my $config=$gls->Config; #isa Config::IniFiles

Example

  my $version=$gls->Config->val("main", "version");

=cut

sub Config {
  my $self=shift;
  my $file=$self->configfile; #support for objects that can stringify paths.
  $self->{'Config'}=Config::IniFiles->new(-file=>"$file")
    unless ref($self->{'Config'}) eq "Config::IniFiles";
  return $self->{'Config'};
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<DateTime::Event::Sunrise>

=cut

1;
