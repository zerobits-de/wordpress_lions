<?php
/**
 * Fallback template (blog index and anything without a more specific template).
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

use Lions\Theme\Controllers\IndexController;

( new IndexController() )->render();
