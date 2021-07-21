php_fpm_reload() {
	php-fpm -t && /bin/kill -USR2 $(cat /var/run/php-fpm.pid)

    echo "PHP_FPM RELOADED"
}

convy_fix_perms(){
	echo "exec funct ${FUNCNAME}"
	if [[ -d "/var/www/" ]];then
	    sh -c "find /var/www/  \! -user www-data -exec chown -h -v www-data:www-data {} +;find /var/www/  \! -group www-data -exec chown -h -v www-data:www-data {} +;"
	fi
}

alias composer='composer'
alias pa='php artisan'
