# fake-names-generator
create fake names or e-mail aliases to be used for anonymity in services.

## Description
fake-names-generator will generate one or more fake names. This is so you
can have fake account names for services, so if one or more get cracked,
they won't be cross referenced and tied back to a single person and
attempts made to crack your other services with the same cracked password.
It's also for services or mailing list subscriptions that you don't
necessarily trust to keep your identity and e-mail address private. If you
find an alias being used by other parties, you can simply remove it from
your mail alias file.

It uses 2 files to create names: a first-names file and a last-names file.
It also uses a file to exclude names created, since you probably don't
want your own name to be randomly created. The exclude names file is the
first and last names separated by white-space. It is not case sensitive.

Names found in the files are converted to lower case, then have the first
letter of each converted to upper-case, then concatenated together with a
connector which defaults to a period. ie: 'BILLY' and 'ARMSTRONG' will
become 'Billy.Armstrong'

It will print unique names only and uses a hash to determine if it
randomly came up with the same name from before. By default it will give
up after $C\_MAX\_DUPLICATES duplicates found, which can be changed with the
-g/--giveup option. If the input names file and the number of wanted names
is too great, it could result in too many attempts to get a unique name.
This prevents an infinite loop.

fake-names-generator will look for the name files in 3 places and use the
first ones it finds. It will first try the current directory, then in the
users directory ~/etc/fake-names-generator, and finally a system directory
of /usr/local/etc/fake-names-generator. The first_names.txt and
last_names.txt files must both exist in at least one location, while the
exclude_names.txt file is optional. Using the --firstnames or --lastnames
options to specify a different name file to use expects a full pathname
and will bypass searching for the file in different directories.

## Example usages
    % fake-names-generator --want 5 --alias barney > /tmp/mail-aliases

    % fake-names-generator --want 500 > /tmp/names

There is a help option.  For eg:

    % fake-names-generator --help

	usage: fake-names-generator [options]*
		[-a|--alias      username]     (/etc/aliases format)
		[-c|--connector  character     (default='.')]
		[-d|--debug]
		[-e|--exclude    filename      (default='./exclude_names.txt')]
		[-f|--firstnames filename      (default='./first_names.txt')]
		[-g|--giveup     number        (default=300)]
		[-h|--help]
		[-l|--lastnames  filename      (default='./last_names.txt')]
		[-v|--version                  (version)]
		[-w|--want       number        (number of names. default=1)]
		[-L|--last-max-len   number    (default=15)]
		[-F|--first-max-len  number    (default=10)]
