<?php
/**
 * Static front page.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

use Lions\Theme\Controllers\FrontPageController;

( new FrontPageController() )->render();
