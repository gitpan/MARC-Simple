#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 102;
BEGIN { use_ok('MARC::Simple') };

my $file = join("", <DATA>);

ok($file, "read file ok");

my $marc = MARC::Simple->new(data => $file);

# use YAML 'Dump';
# print STDERR Dump($marc);
# exit 0;

unless(defined $marc) {
  die "constructor failed";
}
ok($marc->isa("MARC::Simple"), "constructor");

my %test = map { $_=>1, } $marc->get_field_list();

ok( $marc->get_field_list(regexp => qr/0\d\d/) == 7 );
ok( $marc->get_field_list(regexp => '0[45]\d') == 4 );
ok( $marc->get_field_list(regexp => '1\d\d') == 1 );
ok( $marc->get_field_list(regexp => '2\d\d') == 3 );
ok( $marc->get_field_list(regexp => '3\d\d') == 1 );
ok( $marc->get_field_list(regexp => '6\d\d') == 2 );

foreach my $field (qw(
   010 020 040 042 043 050 082 100 245 250 260 300 600 650
)) {
  ok($test{$field}, "field $field returned by get_field_list");
  ok(defined $marc->get_field(field => $field),
     "field $field has a value");
  ok($marc->get_field(field => $field) eq
     $marc->get_field(field => $field, index => 0, subfield => 'a'),
     "get_field defaults to a");
  ok($marc->get_field(field => $field) eq
     $marc->get_field(field => $field, index => 0),
     "index defaults to 0");

  ok($marc->get_field_count(field => $field+2) == 0, "bogus field count");

  if ($field == 650) {
    ok($marc->get_field_count(field => $field) == 3, "field count");
  }
  else {
    ok($marc->get_field_count(field => $field) == 1, "field count");
  }
}

ok($marc->title() eq
   "Bowman\'s store : a journey to myself / Joseph Bruchac.",
   "title");

ok($marc->title_proper() eq
   "Bowman\'s store :",
   "title_proper");

ok($marc->author() eq
   "Bruchac, Joseph, 1942-",
   "author");

ok($marc->edition() eq
   "1st Lee & Low ed.",
   "edition");

ok($marc->publication_date() eq
   "2001.");

# ok($marc->physical_description() eq
#    "315 p. : ill. ; 21 cm.",
#    "physical description");

my @subjects = $marc->get_fields(field => '650', subfields =>['a'..'z']);
ok(@subjects == 3, "subjects");

# ok($subjects[0] eq "Bruchac, Joseph, 1942-");
ok($subjects[0] eq "Abenaki Indians Biography.");
ok($subjects[1] eq "Abenaki Indians Mixed descent.");
ok($subjects[2] eq "Indian authors Biography. New York (State)");

__END__
=LDR    01061cam  22002894a 4500^
001   12269621^
005   20010712140039.0^
008   010104r20011997nyua          000 0aeng  ^
906  _a7_bcbc_corignew_d1_eocip_f20_gy-gencatlg^
9250 _aacquire_b2 shelf copies_xpolicy default^
955  _ato HLCD pc25 01-04-01; sf02 01-11-01; sf12 01-12-01; se50 to Dewey 01-12-01; aa05 01-16-01; bk rec'd, to CIP ver. ps15 06-21-01;_fpv04 2001-07-03 CIP ver to BCCD^
010  _a  2001016435^
020  _a1584300272 (pbk.)^
040  _aDLC_cDLC_dDLC^
042  _apcc^
043  _an-us-ny^
05000_aE99.A13_bB75 2001^
08200_a818/.5409_aB_221^
1001 _aBruchac, Joseph,_d1942-^
24510_aBowman's store :_ba journey to myself /_cJoseph Bruchac.^
250  _a1st Lee & Low ed.^
260  _aNew York, NY :_bLee & Low Books,_c2001.^
300  _a315 p. :_bill. ;_c21 cm.^
60010_aBruchac, Joseph,_d1942-^
650 0_aAbenaki Indians_vBiography.^
650 0_aAbenaki Indians_xMixed descent.^
650 0_aIndian authors_zNew York (State)_vBiography.^
