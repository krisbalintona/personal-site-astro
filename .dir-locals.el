;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((astro-mode . ((eval . (eglot-ensure))))
 (astro-ts-mode . ((eval . (eglot-ensure))))
 (typescript-ts-mode . ((eval . (eglot-ensure))
                        (apheleia-formatter . prettier)))
 (json-ts-mode . ((apheleia-formatter . prettier)))
 (js-ts-mode . ((eval . (eglot-ensure))
                (apheleia-formatter . prettier)))
 (tsx-ts-mode . ((apheleia-formatter . prettier)))
 (nil . ((compile-command . "npm run fix && npm run build")
         (tab-width . 2))))
