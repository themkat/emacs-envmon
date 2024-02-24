;;; envmon.el --- Temperature, humidity and eCO2 with a nice UI -*- lexical-binding: t; -*-

;; URL: https://github.com/themkat/emacs-envmon
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4") (magit-section "3.3.0") (plz "0.7") (dash "2.19.1"))

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
(require 'dash)

(defcustom envmon-url "192.168.10.101"
  "The URL to connect to for pico-environment-monitor."
  :group 'envmon
  :type 'string)

(defcustom envmon-buffer-name "*envmon*"
  "The buffer name for the envmon buffer. Defaults to *envmon*"
  :group 'envmon
  :type 'string)

(defcustom envmon-update-interval 30
  "How often to update the data from the server. Default is every 30 seconds."
  :group 'envmon
  :type 'number)

(defun envmon--get-envmon-data ()
  "Get the actual data. Return value is an alist."
  (condition-case result
      (plz 'get (s-concat envmon-url "/environment.json") :as #'json-read)
    (plz-error
     (error "Could not connect to endpoint. Make sure the URL is correct and the environment monitor is running"))))

(defun envmon--draw-buffer ()
  "Draws the contents of the envmon buffer."
  (let* ((envmon-data (envmon--get-envmon-data))
         (temperature (assoc 'temperature envmon-data))
         (humidity (assoc 'humidity envmon-data))
         (eco2 (assoc 'eCO2 envmon-data))
         (buffer (get-buffer-create envmon-buffer-name)))
    (with-current-buffer buffer
      ;; If we reuse a buffer, it might be readonly
      (setq-local buffer-read-only nil)
      (erase-buffer)

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
      (text-scale-increase 3)
      (switch-to-buffer buffer))))

;; TODO: find a way to update the existing buffer instead of overwriting it each time
(defun envmon--timer-sync ()
  "Called by timer to sync buffer with data from "
  ;; Use if-let to only update buffer (and activate new timer) when buffer is active
  (-if-let (buffer (get-buffer envmon-buffer-name))
      (progn
        (envmon--draw-buffer)
        ;; Don't repeat to have more control or something
        (run-with-timer envmon-update-interval nil 'envmon--timer-sync))))

(defun envmon ()
  "Starts an environment monitor buffer with relevant data."
  (interactive)
  (envmon--draw-buffer)
  (run-with-timer envmon-update-interval nil 'envmon--timer-sync))
