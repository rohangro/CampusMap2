#!/usr/bin/perl
# -----------------------------------------------------------------
# LoadData.pl -- A driver for the LoadData module.
# Copyright 2005 Michael Kelly (jedimike.net)
#
# Thu Mar 24 14:32:56 PST 2005
# -----------------------------------------------------------------

use strict;
use warnings;
use lib qw(./lib);

use LoadData;
use MapGlobals;

my $dir = '.';
my $doPoints = 1;
my $doLocations = 1;
my $doEdges = 1;

if(@ARGV){
	my $arg = shift(@ARGV);
	$doPoints = ($arg =~ /[gp]/i);
	$doLocations = ($arg =~ /l/i);
	$doEdges = ($arg =~ /e/i);
}

my $str = shift(@ARGV);
print "search string is: $str\n";

print "===== Points =====\n";

my $points = LoadData::loadPoints($dir . '/' . $MapGlobals::POINT_FILE);

print STDERR "Loaded " . (keys(%$points)) . " points.\n";


if($doPoints){
	print "Traversing data structure:\n";
	# loop through each point object
	# points are hashed by their ID
	foreach my $pointID ( sort{ $a <=> $b }(keys(%$points)) ){
		# print this point's fields
		print "Point ID: $points->{$pointID}{'ID'}\n";
		print "\tCoordinates: ($points->{$pointID}{'x'}, $points->{$pointID}{'y'})\n";

		# the ID of the location corresponding to this point (0 means no location)
		print "\tLocation ID: $points->{$pointID}{'LocationID'}\n";
		print "\tPassThrough: $points->{$pointID}{'PassThrough'}\n";

		# step through the hash of significant connected points
		print "\tNumber of significant connections: " . (keys %{$points->{$pointID}{'Connections'}}) . "\n";
		foreach my $connID ( sort(keys(%{$points->{$pointID}{'Connections'}})) ){
			# the ID of the connected GraphPoint
			print "\tConnection ID: "
				. "$points->{$pointID}{'Connections'}{$connID}{'ConnectionID'}\n";

			# the weight of the connection (pixel distance * 100)
			print "\t\tWeight: "
				. "$points->{$pointID}{'Connections'}{$connID}{'Weight'}\n";

			# the ID of the corresponding Edge object
			print "\t\tEdge ID: "
				. "$points->{$pointID}{'Connections'}{$connID}{'EdgeID'}\n";
		}

		# step through ALL connected points
		print "\tNumber of connections (ALL CONNECTIONS): "
			. (@{$points->{$pointID}{'ConnectionsArray'}}) . "\n";
		foreach my $connection (@{$points->{$pointID}{'ConnectionsArray'}}){
			# the ID of the connected GraphPoint
			print "\tConnection ID: "
				. "$connection->{'ConnectionID'}\n";

			# the weight of the connection (pixel distance * 100)
			print "\t\tWeight: "
				. "$connection->{'Weight'}\n";

			# the ID of the corresponding Edge object
			print "\t\tEdge ID: "
				. "$connection->{'EdgeID'}\n";
		}
	}
}

print "\n\n===== Locations =====\n";

my $locations = LoadData::loadLocations($dir . '/' . $MapGlobals::LOCATION_FILE);
print STDERR "Loaded " . (keys(%$locations)) . " locations.\n";

if($doLocations){
	print "Traversing data structure:\n";

	# loop through each location key stored in the hashref $locations
	foreach my $locID ( sort{ $a <=> $b }( keys %{$locations->{'ByID'}} ) ){
		# each value in $locations is simply another hash, which has these fields:
		# ID, x, y, PointID, Name
		print "Location ID: $locations->{'ByID'}{$locID}{'ID'} (from key: $locID)\n";
		print "\tName: $locations->{'ByID'}{$locID}{'Name'}\n";
		print "\tNormalized Name: " . LoadData::nameNormalize($locations->{'ByID'}{$locID}{'Name'}) . "\n";
		print "\tBuilding Code: $locations->{'ByID'}{$locID}{'BuildingCode'}\n";
		print "\tCoordinates: ($locations->{'ByID'}{$locID}{'x'}, $locations->{'ByID'}{$locID}{'y'})\n";
		print "\tDisplayName: $locations->{'ByID'}{$locID}{'DisplayName'}\n";
		print "\tPoint ID: $locations->{'ByID'}{$locID}{'PointID'}\n";
		print "\tKeywords: $locations->{'ByID'}{$locID}{'Keywords'}\n";
	}
}

# this is no longer applicable, because we don't load all the edges at once anymore.
#print "\n\n==== Edges =====\n";
#
#my $edges = LoadData::loadEdges($dir . '/' . $MapGlobals::EDGE_FILE);
#print STDERR "Loaded " . (keys(%$edges)) . " edges.\n";
#
#if($doEdges){
#	print "Traversing data structure:\n";
#
#	# loop through each edge key stored in the hashref $edges
#	foreach my $edgeID ( sort{ $a <=> $b }(keys(%$edges) ) ){
#		# print out the fields in this Edge
#		print "Edge ID: $edges->{$edgeID}{'ID'}\n";
#		print "\tStartPoint ID: $edges->{$edgeID}{'StartPoint'}\n";
#		print "\tEndPoint ID: $edges->{$edgeID}{'EndPoint'}\n";
#
#		# now print out the ordered pairs of all the points in this Edge's path
#		print "\tPath Points:\n";
#		foreach my $point ( @{$edges->{$edgeID}{'Path'}} ){
#			print "\t\t($point->{'x'}, $point->{'y'})\n";
#		}
#	}
#}
