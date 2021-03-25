php_fpm_reload() {
	php-fpm -t && /bin/kill -USR2 $(cat /var/run/php-fpm.pid)

    echo "PHP_FPM RELOADED"
}
