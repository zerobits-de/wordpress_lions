<?php
/**
 * Contract for theme feature classes.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme;

interface Registrable {

	/**
	 * Attach WordPress hooks. Must not produce output.
	 */
	public function register(): void;
}
