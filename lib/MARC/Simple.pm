package MARC::Simple;

use 5.006;
use strict;
use warnings;

use Carp;
use Params::Validate ':all';

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

our $VERSION = '0.01_01';

$VERSION = eval $VERSION;

sub new {
  my $class = shift;
  my $self  = {  };

  my %args = validate( @_, {
    data => 1,
  } );

  my $data  = $args{data};

  $self->{_INFO} = _parse_data($data)
    or croak "Unable to parse data";

  bless $self, $class;
  return $self;
}

sub get_field_list {
  my $self   = shift;

  my %args = validate( @_, {
    regexp => { default => qr/\d{3}/ },
  } );

  my $regexp = $args{regexp};
  unless (ref($regexp) eq 'Regexp') {
    $regexp = qr/$regexp/;
  }
  my @fields = sort grep(/$regexp/, keys %{$self->{_INFO}});
  return @fields;
}

sub get_subfield_list {
  my $self   = shift;

  my %args = validate( @_, {
    field => 1,
    index => { default => 0 },
  } );

  my $field  = $args{field};
  my $index  = $args{index};

  if (($index+1) > $self->get_field_count(field => $field)) {
    return;
  }
  return keys %{ $self->{_INFO}->{$field}->[$index] };
}

sub get_field_count {
  my $self  = shift;

  my %args = validate( @_, {
    field => 1,
  } );

  my $field  = $args{field};

  unless (exists $self->{_INFO}->{$field}) {
    return 0;
  }
  return scalar( @{$self->{_INFO}->{$field}} );
}

sub get_field {
  my $self     = shift;

  my %args = validate( @_, {
    field => 1,
    index => { default => 0 },
    subfield => { default => 'a' },
  } );

  my $field  = $args{field};
  my $index  = $args{index};

  if (($index+1) > $self->get_field_count(field => $field)) {
    return;
  }
  my $subfield = $args{subfield};
  return $self->{_INFO}->{$field}->[$index]->{$subfield}
}

sub get_fields {
  my $self  = shift;

  my %args = validate( @_, {
    field => 1,
    index => { default => 0 },
    subfields => { type => ARRAYREF },
  } );

  my $field  = $args{field};
  my $index  = $args{index};

  my $subfields = $args{subfields};

  if (wantarray) {
    my @result = ( );
    while (my $value = $self->get_fields(
       field => $field, index => $index++, subfields => $subfields)) {
      push @result, $value;
    }
    return @result;
  }
  else {
    return join(" ",
       grep( defined($_),
         map { $self->get_field(
                 field    => $field,
                 index    => $index,
                 subfield => $_)
         } @$subfields)
    );
  }
}

sub title {
  return shift->get_fields( field => '245', subfields => [qw( a b c )]);
}

sub title_proper {
  return shift->get_fields( field => '245', subfields => [qw( a n p )]);
}

sub author {
  my $self = shift;
  return
    $self->get_fields( field => '100', subfields => ['a'..'d']) or
    $self->get_fields( field => '110', subfields => ['a'..'d']) or
    $self->get_fields( field => '111', subfields => [qw( a c d )]);
}

sub edition {
  return shift->get_fields( field => '250', index => 0, subfields => ['a']);
}

sub publication_date {
  return shift->get_fields( field => '260', index => 0, subfields => ['c']);
}

# sub physical_description {
#   return shift->get_fields(qw( 300 0 a b c e f g ));
# }

# sub subjects {
#   my $self = shift;
#   my @subj = ( );
#   foreach my $field ($self->get_field_list('6\d\d')) {
#     push @subj, $self->get_fields($field, undef, ('a'..'z'));
#   }  
#   return @subj;
# }

sub _parse_data {
  my $data  = shift;
  my $info  = { };
  
  my ($field, $continued);
  foreach my $line (split /\n/, $data) {
    $line =~ s/\^$//;                   # remove final carat, if it exists
    if (substr($line,0,3) =~ /\d{3}/) {
      $field     = substr($line,0,3);
      $continued = 0;
    }
    elsif (substr($line,0,3) =~ /\s{3}/) {
      $continued = 1;
    }
    if (($field||0) >= 10) {
      $info->{$field} = [ ], unless (exists $info->{$field});
      my @subfields = split /\_/, $line;
      my $count = 0;
      foreach my $sub (@subfields[1..$#subfields]) {
	my $subfield = substr($sub,0,1);
	my $value    = substr($sub,1);
	unless ($continued || $count) {
	  push @{$info->{$field}}, { };
	}
	$info->{$field}->[-1]->{$subfield} = $value;
	$count++;
      }
    }
  }
  return $info;
}

1;
__END__

=head1 NAME

MARC::Simple - Rudimentary parsing of MARC format bibliographic data

=head1 SYNOPSIS

  use MARC::Simple;

  $marc = MARC::Simple->new( data => $data );

  $author = $marc->get_fields( field => '245', subfields => [qw(a b c)] );
  $title  = $marc->get_fields( field => '245', subfields => [qw(a n p)] );

=head1 DESCRIPTION

This module performs some very rudimentary parsing (it parses
field/subfield values but ignores indicators) of MARC MicroLIF format
bibliographic data.

=head2 Methods

=over

=item new

  $marc = MARC::Simple->new( data => $data );

Creates a new C<MARC::Simple> object, where data is a simple record
for one bibliographic entry.

=item get_fields_list

  @fields = $marc->get_fields_list()

  @fields = $marc->get_fields_list( regexp => $regexp );

  @fields = $marc->get_fields_list( regexp => qr/$regexp/ );

Returns a sorted list of fields matching the given regular expression,
or all fields if none is given.

=item get_subfield_list

=item get_field_count

  $count = $marc->get_field_count( field => $field );

Returns the number of indices for the given field.  In most cases,
this is C<1>.

=item get_field

  $value = $marc->get_field(
    field => $field, index => $index, subfield => $subfield
  );

Returns the value of the subfield from the I<index+1> th occurrence of
the field.

If index is not specified, it is assumed to be C<0>.

If subfield is not specified, it is assumed to be C<a>.

=item get_fields

  $value = $marc->get_fields(
    field => $field, index => $index, subfields => \@subfields
  );

Returns several subfields in the order specified joined by a space.

If called in a list context, it will return all indices:

  @values = $marc->get_fields(
    field => $field, subfields => \@subfields
  );

=back

=head1 SEE ALSO

This module was written for a project that was abandoned before
completion.  B<So this code is unsupported>, but released because it was
already written, and may be of use to somebody.

If it does not meet your needs, then please look at the following Perl
modules:

  MARC
  MARC::Record

=head1 AUTHOR

Robert Rothenberg, E<lt>rrwo at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Robert Rothenberg. All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
