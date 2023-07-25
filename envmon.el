;;; envmon.el --- Temperature, humidity and eCO2 with a nice UI -*- lexical-binding: t; -*-

;; URL: https://github.com/themkat/emacs-envmon
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (magit-section "3.3.0") (plz "0.7"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Integrates with pico-environment-monitor to get temperature, humidity
;;  and eCO2, and presents them in a nice way in Emacs. Probably only ever
;;  useful to themkat, unless someone builds one themselves :P

;;; Code:

(require 'magit-section)
(require 'plz)

;; TODO: actually call the endpoints to fetch data. Is there a more modern request.el? or is that still the best?

;; TODO: timer to continously update the data

;; TODO: use existing *envmon* buffer if possible?

(defcustom envmon-url "192.168.10.101"
  "The URL to connect to for pico-environment-monitor."
  :group 'envmon
  :type 'string)

;; TODO: error handling of some kind?
(defun envmon--get-envmon-data ()
  ;; TODO: should we convert it in any way?
  (plz 'get (s-concat envmon-url "/environment.json") :as #'json-read))

(defun envmon ()
  (interactive)
  (let* ((buffer (generate-new-buffer "*envmon*"))
         (envmon-data (envmon--get-envmon-data))
         (temperature (assoc 'temperature envmon-data))
         (humidity (assoc 'humidity envmon-data))
         (eco2 (assoc 'eCO2 envmon-data)))
    (with-current-buffer buffer
      (magit-insert-section ("Envmon")
        (magit-insert-heading "Environment Monitor")
        ;; TODO: is there a prettifer way to do this? or insert an image? :P 
        (magit-insert-section ("temp")
          (magit-insert-heading "Temperature")
          (insert (format "%.1f" (cdr temperature)))
          (insert "\n"))
        (insert "\n")
        (magit-insert-section ("humidity")
          (magit-insert-heading "Humidity")
          (insert (format "%.0f" (cdr humidity)))
          (insert " %")
          (insert "\n"))
        (insert "\n")
        (magit-insert-section ("eco2")
          (magit-insert-heading "eCO2")
          (insert (format "%d" (cdr eco2)))
          (insert " ppm")
          (insert "\n")))
      (magit-section-mode)
      (switch-to-buffer buffer))))
