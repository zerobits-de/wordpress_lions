<?php
/**
 * Archives (categories, tags, dates, authors).
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

use Lions\Theme\Controllers\ArchiveController;

( new ArchiveController() )->render();
