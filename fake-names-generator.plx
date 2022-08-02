#!/usr/bin/env perl

# generate a bunch of fake names, suitable for an alias file for mail.
# This is so we can have fake account names for services, so if one or
# more get cracked, they won't be cross referenced and tied back to a
# single person and attempts made to crack your other services with the
# same cracked password.
#
# use perldoc to see more description
#
# RJ White
# rj@moxad.com

use strict ;
use warnings ;

my $G_progname = $0 ;
$G_progname    =~ s/^.*\/// ;
my $G_debug    = 0 ;
my $G_version  = '1.1' ;

my $C_MAX_DUPLICATES = 300 ;   # max allowed duplicates when creating names

if ( main()) {
    exit(1) ;
} else {
    exit(0) ;
}


sub main {
    # files of data
    my $first_names_file   = 'first_names.txt' ;
    my $last_names_file    = 'last_names.txt' ;
    my $exclude_names_file = 'exclude_names.txt' ;
    my $first_name_max     = 10 ;
    my $last_name_max      = 15 ;
    my $name_connector     = '.' ;
    my $want               = 1 ;
    my $alias              = undef ;
    my $alias_option       = 0 ;
    my $give_up_value       = $C_MAX_DUPLICATES ;

    my ( $full_first_file, $full_last_file, $full_exclude_file ) ;
    $full_first_file  = $full_last_file = $full_exclude_file = undef ;

    for ( my $i = 0 ; $i <= $#ARGV ; $i++ ) {
        my $arg = $ARGV[ $i ] ;
        if (( $arg eq "-d" ) or ( $arg eq "--debug" )) {
            $G_debug++ ;
        } elsif (( $arg eq "-v" ) or ( $arg eq "--version" )) {
            print "version: $G_version\n" ;
            return(0) ;
        } elsif (( $arg eq "-g" ) or ( $arg eq "--giveup" )) {
            $give_up_value = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-f" ) or ( $arg eq "--firstnames" )) {
            $full_first_file = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-l" ) or ( $arg eq "--lastnames" )) {
            $full_last_file = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-e" ) or ( $arg eq "--exclude" )) {
            $full_exclude_file = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-F" ) or ( $arg eq "--first-max-len" )) {
            $first_name_max = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-L" ) or ( $arg eq "--last-max-len" )) {
            $last_name_max = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-w" ) or ( $arg eq "--want" )) {
            $want = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-a" ) or ( $arg eq "--alias" )) {
            $alias_option = 1 ;
            $alias = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-c" ) or ( $arg eq "--connector" )) {
            $name_connector = $ARGV[ ++$i ] ;
        } elsif (( $arg eq "-h" ) or ( $arg eq "--help" )) {
            printf "usage: $G_progname [option]*\n" .
              "%s %s %s %s %s %s %s %s %s %s %s %s",
                "\t[-a|--alias username]           (/etc/aliases format)\n",
                "\t[-c|--connector character]      (default=\'$name_connector\')\n",
                "\t[-d|--debug]\n",
                "\t[-e|--exclude filename]         (default=\'" .
                    find_file( $exclude_names_file, "" ) . "\')\n",
                "\t[-f|--firstnames filename]      (default=\'" .
                    find_file( $first_names_file, "" ) . "\')\n",
                "\t[-g|--giveup number]            (default=$give_up_value)\n",
                "\t[-h|--help]\n",
                "\t[-l|--lastnames filename]       (default=\'" .
                    find_file( $last_names_file, "" ) . "\')\n",
                "\t[-v|--version]                  (version)\n",
                "\t[-w|--want number]              (number of names. default=$want)\n",
                "\t[-L|--last-max-len number]      (default=$last_name_max)\n",
                "\t[-F|--first-max-len number]     (default=$first_name_max)\n" ;
            return(0) ;
        } else {
            print_error( "Unknown option: $arg" ) ;
            return(1) ;
        }
    }

    # sanity checks
    if ( $give_up_value !~ /^\d+$/ ) {
        print_error( "give-up value is not a number: $give_up_value" ) ;
        return(1) ;
    }
    if ( not defined( $want )) {
        print_error( "want option -w/--want given without a value" ) ;
        return(1) ;
    }
    if (( $want !~ /^\d+$/ ) or ( $want eq '0' )) {
        print_error( "The number of names wanted must be a positive number" ) ;
        return(1) ;
    }
    if ( $give_up_value > $C_MAX_DUPLICATES ) {
        print_error( "give-up value is unreasonably large.  " .
            "Make it <= $C_MAX_DUPLICATES" ) ;
        return(1) ;
    }

    # go look for the data files.  Accept the first place found with
    # order preference being current-dir, user-dir and system-dir

    if ( not defined( $full_first_file )) {
        $full_first_file = find_file( $first_names_file ) 
    }
    if ( not defined( $full_last_file )) {
        $full_last_file = find_file( $last_names_file ) 
    }
    if ( not defined( $full_exclude_file )) {
        $full_exclude_file = find_file( $exclude_names_file ) 
    }

    my @required_filenames = ( $full_first_file, $full_last_file ) ;

    my @max_lengths   = ( $first_name_max, $last_name_max ) ;
    my %first_names   = () ;
    my %last_names    = () ;
    my @names         = ( \%first_names, \%last_names ) ;

    # read in the names into arrays

    my $num_errs = 0 ;
    for ( my $i = 0 ; $i < 2 ; $i++ ) {
        my $file = $required_filenames[ $i ] ;
        if ( ! -f $file ) { 
            print_error( "no such file: $file" ) ;
            $num_errs++ ;
            next ;
        }

        my $fd ;
        my $count = 0 ;
        if ( ! ( open( $fd, "<", $file ))) {
            print_error( "can't open file: $file" ) ;
            $num_errs++ ;
            next ;
        }
        my @tmp_names = <$fd> ;
        chomp( @tmp_names ) ;

        my $total_num = scalar( @tmp_names ) ;
        my $skipped = 0 ;
        my $len = $max_lengths[ $i ] ;
        dprint( "using MAX length of $len for name in $file" ) ;
        my $hash_ref = $names[$i] ;
        foreach my $name ( @tmp_names ) {
            next if ( $name eq "" ) ;
            next if ( $name =~ /^\#/ ) ;      # skip if a comment
            if ( length( $name ) > $len ) {
                $skipped++ ;
                next ;
            }
            # make sure it looks like a name
            # use a hash so they are unique
            if ( $name =~ /^\s*([a-zA-Z]+)\s*$/ ) {
                $name = ucfirst( lc( $1 )) ;
                ${$hash_ref}{ $name } = 1 ;
            }
        }
        my $num = keys ( %$hash_ref ) ;
        dprint( "Got $num acceptable names from $file" ) ;
        if ( $num == 0 ) {
            print_error( "ended up with 0 names from $file" ) if ( $num == 0 ) ;
            $num_errs++ ;
        }
        dprint( "skipped $skipped names (too long) out of " .
                "$total_num in $file" ) ;

    }
    return(1) if ( $num_errs ) ;

    # now move the data into arrays for easier handling later

    my @last_names = keys( %last_names ) ;
    my @first_names = keys( %first_names ) ;

    # see if there is an exclusion list of names

    my %exclude_names = () ;
    if ( -f $full_exclude_file ) {
        my $fd ;
        if ( open( $fd, "<", $full_exclude_file )) {
            my @names = <$fd> ;
            chomp( @names ) ;
            foreach my $name ( @names ) {
                next if ( $name eq "" ) ;
                next if ( $name =~ /^\#/ ) ;      # skip if a comment
                # expecting format of "firstname lastname"
                if ( $name =~ /^(\s*[A-Za-z\']+)\s+([A-Za-z\']+)\s*$/ ) {
                    $name = ucfirst( lc( $1 )) .
                            $name_connector .
                            ucfirst( lc( $2 )) ;
                    $exclude_names{ $name } = $name ;
                } else {
                    dprint( "skipping exclude name of $name" ) ;
                }
            }
            close( $fd ) ;
        }

        my $num = scalar( keys( %exclude_names )) ;
        dprint( "we have $num predefined names to exclude in $full_exclude_file" ) ;
    }

    # put together a full name

    my $num_first_names = @first_names ;
    my $num_last_names  = @last_names ;

    my %full_names = () ;
    my $duplicates = 0 ;
    my $count = 0 ;
    while ( $count < $want ) {
        my $n1 = @first_names[ int( rand( $num_first_names )) ] ;
        my $n2 = @last_names[  int( rand( $num_last_names )) ] ;
        my $full_name = "${n1}${name_connector}${n2}" ;

        # skip if it is a name given to exclude
        if ( defined( $exclude_names{ $full_name } )) {
            dprint( "skipping EXCLUDE NAME: $full_name" ) ;
            next ;
        }

        # skip if we already tried to create this same fake name
        if ( defined( $full_names{ $full_name } )) {
            dprint( "already have $full_name.  Skipping..." ) ;
            $duplicates++ ;
            if ( $duplicates > $C_MAX_DUPLICATES ) {
                my $err = "giving up after too many tries for unique name" ;
                print_error( $err ) ;
                if ( $count < $want ) {
                    my $ending = ($count == 1) ? "" : 's' ;
                    print_error( "only created $count name" . $ending ) ;
                }
                last ;
            }
            next ;
        }

        # shove into a hash to assure uniqueness
        $full_names{ $full_name } = 1 ;
        $count++ ;
    }

    # if creating entries for a mail alias file, let's make it
    # pretty and line things up.  Get the max length of our names

    my $max_len = 0 ;
    my $field_width = 10 ;		# min start width
    if ( defined( $alias )) {
        foreach my $name ( keys( %full_names )) {
            my $len = length( $name ) ;
            $max_len = $len if ( $len > $max_len ) ;
        }
        dprint( "length of longest name is $max_len" ) ;
        $field_width = $max_len + 5 ;
        dprint( "setting field width of name to $field_width" ) ;
    } else {
        if ( $alias_option) {
            print_error( "need to provide alias with -a/--alias option" ) ;
            return(1)
        }
    }

    foreach my $name ( keys( %full_names )) {
        if ( defined( $alias )) {
            $name = "${name}:" ;
            printf( "%-${field_width}s%s\n", $name, $alias );
        } else {
            print "$name\n" ;
        }
    }
    dprint( "created $count names" ) ;
    return(0) ;
}


# return the full pathname of a file.
# return an undef if not found, unless the preferred return value
# is passed as a 2nd argument
#
# Arguments:
#    1: filename
#    2: optional return value if file not found
# Returns:
#    full-pathname or undef
# Globals:
#    none

sub find_file {
    my $file = shift ;
    my $nf_return = shift ;

    my $home = $ENV{ 'HOME' } ;
    my @data_dirs = ( ".", 
                      "${home}/etc/fake-names-generator", 
                      "/usr/local/etc/fake-names-generator" ) ;

    my $return_value = undef ;
    $return_value = $nf_return if ( defined( $nf_return )) ;
    for my $dir ( @data_dirs ) {
        my $fname = "$dir/$file" ;
        if ( -f $fname ) {
            dprint( "found $file in $dir" ) ;
            return( $fname ) ;
        }
    }
    return( $return_value ) ;
}



# print a debug statement to stderr
#
# Arguments:
#    1: string to print
# Returns:
#    0
# Globals:
#    none

sub dprint {
    my $str = shift ;

    return(0) if ( $G_debug == 0 ) ;

    print STDERR "debug: $str\n" ;
    return(0) ;
}



# print an error message to stderr
#
# Arguments:
#    1: string to print
# Returns:
#    0
# Globals:
#    $G_progname

sub print_error {
    my $err = shift ;

    print STDERR "$G_progname: $err\n" ;
    return(0) ;
}

__END__

=head1 NAME

fake-names-generator - create fake names

=head1 SYNOPSIS

fake-names-generator [option]*

=head1 DESCRIPTION

fake-names-generator will generate one or more fake names.
This is so you can have fake account names for services, so if one or
more get cracked, they won't be cross referenced and tied back to a
single person and attempts made to crack your other services with the
same cracked password.  It's also for services or mailing list
subscriptions that you don't necessarily trust to keep your identity
and e-mail address private.  If you find an alias being used by other
parties, you can simply remove it from your mail alias file.

It uses 2 files to create names: a first-names file and a last-names file.
It also uses a file to exclude names created, since you probably don't
want your own name to be randomly created.  The exclude names file is
the first and last names separated by white-space.  It is not case sensitive.

Names found in the files are converted to lower case, then have the first
letter of each converted to upper-case, then concatenated together with a
connector which defaults to a period.
   ie:  'BILLY' and 'ARMSTRONG' will become 'Billy.Armstrong'

It will print unique names only and uses a hash to determine if it randomly
came up with the same name from before.  By default it will give up after
$C_MAX_DUPLICATES duplicates found, which can be changed with the -g/--giveup
option.  If the input names file and the number of wanted names is too great,
it could result in too many attempts to get a unique name.  This prevents an
infinite loop.

fake-names-generator will look for the name files in 3 places and use the
first ones it finds.  It will first try the current directory, then in
the users directory ~/etc/fake-names-generator, and finally a system
directory of /usr/local/etc/fake-names-generator.  The first_names.txt
and last_names.txt files must both exist in at least one location, while the
exclude_names.txt file is optional.  Using the --firstnames or --lastnames
options to specify a different name file to use expects a full pathname and
will bypass searching for the file in different directories.

=head1 OPTIONS

 -a | --alias          username    create /etc/aliases format for alias given
 -c | --connector      character   connector for first and last names
 -d | --debug                      turn on debugging and informative output.
 -e | --exclude        filename    filename of exclusion names
 -f | --firstnames     filename    filename of first names
 -g | --giveup         number      give up after this number of duplicates (300)
 -h | --help                       print out options
 -l | --lastnames      filename    filename of last names
 -v | --version                    print the program version number
 -w | --want           number      number of fake names wanted (1)
 -L | --last-max-len   number      maximum length of last name to use 
 -F | --first-max-len  number      maximum length of first name to use

=head1 EXAMPLE

 # create 5 fake names in /etc/aliases format
 % fake-names-generator --want 5 --alias barney > /tmp/extra-mail-aliases
 %
 % cat /tmp/extra-mail-aliases
 Billy.Conrad:     barney
 Brent.Brennan:    barney
 Harold.Villa:     barney
 Casey.Larson:     barney
 Pedro.Bruce:      barney

=head1 FILES

 exclude_names.txt
 first_names.txt
 last_names.txt

=head1 DIRECTORIES checked for data FILES

 .
 ${HOME}/etc/fake-names-generator
 /usr/local/etc/fake-names-generator

=head1 AUTHOR

 RJ White 
 rj@moxad.com
