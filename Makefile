PROGNAME	= fake-names-generator
USER_DATA_DIR   = ${HOME}/etc/${PROGNAME}
ROOT_DATA_DIR   = /usr/local/etc/${PROGNAME}
USER_DEST_DIR   = ${HOME}/bin
ROOT_DEST_DIR   = /usr/local/bin
DATA_FILES = first_names.txt last_names.txt exclude_names.txt

install: install-bin install-data

install-bin:
	@if [ `whoami` = 'root' ]; then \
		echo "I am Groot!" ; \
		echo "Installing ${PROGNAME} into ${ROOT_DEST_DIR}" ; \
		install -p ${PROGNAME}.plx ${ROOT_DEST_DIR}/${PROGNAME} ; \
	else \
		echo "I am NOT Groot! I am just a normal user :-(" ; \
		echo "Installing ${PROGNAME} into ${USER_DEST_DIR}" ; \
		install -p ${PROGNAME}.plx ${USER_DEST_DIR}/${PROGNAME} ; \
	fi

install-data:
	@if [ `whoami` = 'root' ]; then \
		echo "I am Groot!" ; \
		mkdir -p ${ROOT_DATA_DIR} ; \
		for file in ${DATA_FILES} ; do \
			if [ ! -f ${ROOT_DATA_DIR}/$${file} ]; then \
				echo installing $$file into ${ROOT_DATA_DIR}/$${file} ; \
				install -p $$file ${ROOT_DATA_DIR}/$${file} ; \
			else \
				echo $$file already exists in ${ROOT_DATA_DIR} - NOT over-writing ; \
			fi \
		done \
	else \
		echo "I am NOT Groot! maybe some day..." ; \
		mkdir -p ${USER_DATA_DIR} ; \
		for file in ${DATA_FILES} ; do \
			if [ ! -f ${USER_DATA_DIR}/$${file} ]; then \
				echo installing $$file into ${USER_DATA_DIR}/$${file} ; \
				install -p $$file ${USER_DATA_DIR}/$${file} ; \
			else \
				echo $$file already exists in ${USER_DATA_DIR} - NOT over-writing ; \
			fi \
		done \
	fi
