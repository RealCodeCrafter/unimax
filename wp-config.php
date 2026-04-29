<?php
//Begin Really Simple SSL session cookie settings
@ini_set('session.cookie_httponly', true);
@ini_set('session.cookie_secure', true);
@ini_set('session.use_only_cookies', true);
//END Really Simple SSL cookie settings

// Railway/Reverse proxy: if the outside request is HTTPS, force WordPress to treat it as HTTPS.
if ( isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && strtolower($_SERVER['HTTP_X_FORWARDED_PROTO']) === 'https' ) {
	define('WP_FORCE_HTTPS', true);
	$_SERVER['HTTPS'] = 'on';
}

// Public URL: use Railway’s domain for this deployment (changes when you create a new service URL).
if ( ! empty( getenv( 'RAILWAY_PUBLIC_DOMAIN' ) ) ) {
	$_unimax_public_base = 'https://' . getenv( 'RAILWAY_PUBLIC_DOMAIN' );
	define( 'WP_HOME', $_unimax_public_base );
	define( 'WP_SITEURL', $_unimax_public_base );
} else {
	// Fallback for local / custom host (override via PUBLIC_SITE_URL in Railway if needed).
	$_unimax_fallback = getenv( 'PUBLIC_SITE_URL' ) ?: 'https://unimax-production-0b0a.up.railway.app';
	define( 'WP_HOME', $_unimax_fallback );
	define( 'WP_SITEURL', $_unimax_fallback );
}

/**
 * Основные параметры WordPress.
 *
 * Скрипт для создания wp-config.php использует этот файл в процессе установки.
 * Необязательно использовать веб-интерфейс, можно скопировать файл в "wp-config.php"
 * и заполнить значения вручную.
 *
 * Этот файл содержит следующие параметры:
 *
 * * Настройки MySQL
 * * Секретные ключи
 * * Префикс таблиц базы данных
 * * ABSPATH
 *
 * @link https://ru.wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Параметры базы данных: Эту информацию можно получить у вашего хостинг-провайдера ** //
/** Имя базы данных для WordPress */
// Static Railway PUBLIC MySQL credentials (no env usage)
define( 'DB_NAME', 'railway' );

/** Имя пользователя базы данных */
define( 'DB_USER', 'root' );

/** Пароль к базе данных */
define( 'DB_PASSWORD', 'VRDmNMvzkAoSmMjRVJCbuerGzwpdmcor' );

/** Имя сервера базы данных (host:port) */
define( 'DB_HOST', 'switchyard.proxy.rlwy.net:52692' );

/** Кодировка базы данных для создания таблиц. */
define( 'DB_CHARSET', 'utf8mb4' );

/** Схема сопоставления. Не меняйте, если не уверены. */
define( 'DB_COLLATE', '' );

/**#@+
 * Уникальные ключи и соли для аутентификации.
 *
 * Смените значение каждой константы на уникальную фразу. Можно сгенерировать их с помощью
 * {@link https://api.wordpress.org/secret-key/1.1/salt/ сервиса ключей на WordPress.org}.
 *
 * Можно изменить их, чтобы сделать существующие файлы cookies недействительными.
 * Пользователям потребуется авторизоваться снова.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '@,Su24UD@n]/)UY7VuR7%er|?.GFhgGSNHAV+XTGq>h<+.UODh.Zgz]Y8sU(j%Xf' );
define( 'SECURE_AUTH_KEY',  'n/CxP6*uO2ZSh/x5PwI|k=Nci:Y~, O k0,dqEg~MUs&q=SpTK2(}Z0P>.+`V7 s' );
define( 'LOGGED_IN_KEY',    'X(ddwG(tNmeWR2Jx:)E /^u>KV,6fU/ej;RTf)|i`Z=W.]_*YFK%&QpmX)8FxD9/' );
define( 'NONCE_KEY',        'Z;]Ws_fABZ:>8j[qQ)j:lT9Z/{Y([=DnKukk_[o<HNL4T{0lH24eL4sGIce[-_/Z' );
define( 'AUTH_SALT',        'lqS+us[Ci?00Osg<?g)UkeG!$;>9sn?yD!+]X-)dfqb<r_,|Se+E?PbWs/|b2`)<' );
define( 'SECURE_AUTH_SALT', 'NoHg[~/2peowJH7EcXr|Zmp:-ftVo`@O?5~ls.:cAYD5hN5+-d|k;DZ1d9W]oXQf' );
define( 'LOGGED_IN_SALT',   'mT=J#|1$CC-Dn!^r_nF TLt>Iou-SmxlX%AKZl@2IGrehgaE6#Bx.NrQ;=pl_mLS' );
define( 'NONCE_SALT',       'lfSM1w[J]hn;r)WXu:H&z/^c=Yztbe:(t+TvEkQ,ky{*2!GoTu@18dXun;),eu?~' );

/**#@-*/

/**
 * Префикс таблиц в базе данных WordPress.
 *
 * Можно установить несколько сайтов в одну базу данных, если использовать
 * разные префиксы. Пожалуйста, указывайте только цифры, буквы и знак подчеркивания.
 */
$table_prefix = 'hihqh_';

/**
 * Для разработчиков: Режим отладки WordPress.
 *
 * Измените это значение на true, чтобы включить отображение уведомлений при разработке.
 * Разработчикам плагинов и тем настоятельно рекомендуется использовать WP_DEBUG
 * в своём рабочем окружении.
 *
 * Информацию о других отладочных константах можно найти в документации.
 *
 * @link https://ru.wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Произвольные значения добавляйте между этой строкой и надписью "дальше не редактируем". */



/* Это всё, дальше не редактируем. Успехов! */

/** Абсолютный путь к директории WordPress. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Инициализирует переменные WordPress и подключает файлы. */
require_once ABSPATH . 'wp-settings.php';
