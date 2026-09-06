<?php
/**
 * 404 - not found.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

use Lions\Theme\Controllers\NotFoundController;

( new NotFoundController() )->render();
