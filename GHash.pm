package Tie::GHash;

use strict;
use warnings;

require Exporter;
use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tie::GHash ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.10';

use Inline C => Config =>
  LIBS => `glib-config --libs`,
  INC => `glib-config --cflags`;

use Inline C => 'DATA',
  VERSION => '0.10',
  NAME => 'Tie::GHash';


# Preloaded methods go here.

=head1 NAME

Tie::GHash - A smaller hash

=head1 SYNOPSIS

  tie my %words, 'Tie::GHash';
  my $i;
  foreach (@words) {
    $words{$_} = $i++;
  }

=head1 DESCRIPTION

This module provides an interface to the Gnome glib library's hashes,
which are smaller (although possibly slower) than Perl's internal
hashes.

Typically, Perl sacrifices memory for speed, and this is the case with
its built-in hashes. Occasionally, you have a need for a large in-memory
hash, where it would be useful to sacrifice speed for low memory
usage. This module provides that functionality.

Using C<Tie::GHash> is very simple: just use the hash in exactly the
same way as you would use a normal Perl hash, with the exception that
you need to C<tie> it before use as in the synopsis.

For example, reading in a typical /usr/share/dict/words using Perl's
built in hashes took up 8,672K. Doing the same with Tie::GHash took up
7,212K, albeit about six times slower due to the tie interface.

=head1 NOTES

This module requires a recent version of the Inline library. This
module was created during Brian Ingerson's Inline talk at
YAPC::NorthAmerica 2001 when he asked me to code something fun using
Inline, so blame him.

=head1 BUGS

FIRSTKEY and NEXTKEY are currently unimplemented, which means that
C<foreach> will not work over such a hash. Patches welcome.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__C__
#include <glib.h>

SV* TIEHASH(char* class) {
  GHashTable* h = g_hash_table_new(g_str_hash, g_str_equal);
  SV* obj_ref = newSViv(0);
  SV*     obj = newSVrv(obj_ref, class);

  sv_setiv(obj, (IV)h);
  SvREADONLY_on(obj);
  return obj_ref;
}

void STORE(SV* obj, char* key, char* value) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  char *old_key, *old_value;

  if (g_hash_table_lookup_extended(h, key, &old_key, &old_value)) {
    /* printf(".. replacing insert %s => %s (was %s => %s)\n", key, value, old_key, old_value); */
    g_hash_table_insert(h, old_key, g_strdup(value));
    g_free(old_value);
  } else {
    /* printf(".. simple insert %s => %s\n", key, value);*/
    g_hash_table_insert(h, g_strdup(key), g_strdup(value));
  }
}

char* FETCH(SV* obj, char* key) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  return g_hash_table_lookup(h, key);
}

char* EXISTS(SV* obj, char* key) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  return g_hash_table_lookup(h, key);
}

int size(SV* obj) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  return g_hash_table_size(h);
}

void DELETE(SV* obj, char* key) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  char *old_key, *old_value;

  if (g_hash_table_lookup_extended(h, key, &old_key, &old_value)) {
    g_hash_table_remove(h, key);
    g_free(old_key);
    g_free(old_value);
  }
}

static void free_a_hash_table_entry(gpointer key, gpointer value, gpointer user_data) {
  g_free(key);
  g_free(value);
}

void CLEAR(SV* obj) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  g_hash_table_foreach(h, free_a_hash_table_entry, NULL);
}

void DESTROY(SV* obj) {
  GHashTable* h = (GHashTable*)SvIV(SvRV(obj));
  CLEAR(obj);
  g_hash_table_destroy(h);
}


__END__
