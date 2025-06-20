;; gerbil scheme for generating zmk configs
;; This file implements a "compiler" for ZMK configs from s-expressions

(import :gerbil/gambit)
(import :std/pregexp)
(define (generate-header config)
  (display "Header config: ") 
  (newline)
  
  (let* ((header-config (if (assoc 'header config)
                           (car (cdr (assoc 'header config)))
                           '()))
         
         ;; Extract configuration values with better handling for nested lists
         (copyright-item (and (not (null? header-config)) (assoc 'copyright header-config)))
         (license-item (and (not (null? header-config)) (assoc 'license header-config)))
         (includes-item (and (not (null? header-config)) (assoc 'includes header-config)))
         
         ;; Get actual values with defaults
         (copyright (if copyright-item 
                       (cadr copyright-item) 
                       "Copyright (c) 2020 The ZMK Contributors"))
         (license (if license-item 
                     (cadr license-item) 
                     "MIT"))
         (includes (if includes-item 
                      (cadr includes-item) 
                      '("behaviors.dtsi" "dt-bindings/zmk/bt.h" "dt-bindings/zmk/keys.h" "dt-bindings/zmk/mouse.h"))))
    
    (display "Copyright item: ") (display copyright-item) (newline)
    (display "Final copyright: ") (display copyright) (newline)
    
    (string-append
     "/*\n * " copyright "\n *\n * SPDX-License-Identifier: " license "\n */\n\n"
     (apply string-append
            (map (lambda (inc)
                   (string-append "#include <" inc ">\n"))
                 includes))
     "\n")))

;; No hardcoded configurations anymore - they are now loaded from an external file

;; Default output filename
(define output-filename "gen.keymap")

;; Generate modtap settings from configuration
(define (generate-modtap-settings settings)
  (display "Debugging modtap settings: ") (display settings) (newline)
  (let* ((actual-settings (car settings))  ; Extract the first list which contains the settings
         (result ""))
    
    ;; Process all settings provided in the config
    (string-append
      "&mt {\n"
      (apply string-append
        (map (lambda (setting-pair)
               (let ((key (car setting-pair))
                     (value (cadr setting-pair)))
                 (cond
                  ;; Different types of settings need different formatting
                  ((equal? key 'flavor)
                   (string-append "    flavor = \"" value "\";\n"))
                  ((equal? key 'quick-tap-ms)
                   (string-append "    quick-tap-ms = <" (number->string value) ">;\n"))
                  ;; Add other types of settings here (tapping-term-ms, etc.)
                  ((equal? key 'tapping-term-ms)
                   (string-append "    tapping-term-ms = <" (number->string value) ">;\n"))
                  ((equal? key 'retro-tap)
                   (string-append "    retro-tap;\n"))
                  ;; Any other settings we want to support
                  (else
                   (string-append "    " (symbol->string key) " = <" (number->string value) ">;\n")))))
          actual-settings))
      "};\n\n")))

(define (generate-root-begin)
  "/ {\n")

(define (generate-root-end)
  "};\n")

(define (generate-chosen config)
  (let ((transform (if (assoc 'matrix_transform config)
                      (cadr (assoc 'matrix_transform config))
                      "five_column_transform"))) ; Default if not specified
    (display "Matrix transform: ") (display transform) (newline)
    (string-append "    chosen { zmk,matrix_transform = &" transform "; };\n\n")))

(define (join-with-space lst)
  (apply string-append
         (map (lambda (item index)
                (if (= index 0)
                    (number->string item)
                    (string-append " " (number->string item))))
              lst
              (iota (length lst)))))

(define (iota n)
  (let loop ((i 0) (result '()))
    (if (= i n)
        (reverse result)
        (loop (+ i 1) (cons i result)))))

(define (generate-combos config-combos)
  (display "Debugging combos: ") (display config-combos) (newline)
  (if (null? config-combos)
      ""  ; Return empty string if no combos
      (let ((actual-combos (car config-combos)))  ; Extract the actual combos list
        (string-append
         "    combos {\n"
         "        compatible = \"zmk,combos\";\n\n"
         (apply string-append
                (map (lambda (combo)
                       (let* ((name (car combo))
                              (props (cdr combo))
                              (timeout (cadr (assoc 'timeout-ms props)))
                              (key-pos (cadr (assoc 'key-positions props)))
                              (bind (cadr (assoc 'bindings props))))
                         (string-append
                          "        " (symbol->string name) " {\n"
                          "            timeout-ms = <" (number->string timeout) ">;\n"
                          "            key-positions = <" (join-with-space key-pos) ">;\n"
                          "            bindings = <" bind ">;\n"
                          "        };\n")))
                     actual-combos))
         "    };\n\n"))))

(define (join-bindings lst)
  (apply string-append
         (map (lambda (item index)
                (if (= index 0)
                    item
                    (string-append ">, <" item)))
              lst
              (iota (length lst)))))

(define (generate-behaviors config-behaviors)
  (display "Debugging behaviors: ") (display config-behaviors) (newline)
  (if (null? config-behaviors)
      ""  ; Return empty string if no behaviors
      (let ((actual-behaviors (car config-behaviors)))  ; Extract the actual behaviors list
        (string-append
         "    behaviors {\n"
         (apply string-append
                (map (lambda (behavior)
                       (let* ((name (car behavior))
                              (props (cdr behavior))
                              (compatible (cadr (assoc 'compatible props)))
                              (label (cadr (assoc 'label props)))
                              (binding-cells (cadr (assoc 'binding-cells props)))
                              (bindings (and (assoc 'bindings props) (cadr (assoc 'bindings props))))
                              (tapping-term (and (assoc 'tapping-term-ms props) (cadr (assoc 'tapping-term-ms props))))
                              (flavor (and (assoc 'flavor props) (cadr (assoc 'flavor props)))))
                         (string-append
                          "        " (symbol->string name) ": " (symbol->string name) " {\n"
                          "            compatible = \"" compatible "\";\n"
                          "            label = \"" label "\";\n"
                          (if bindings
                              (string-append
                               "            bindings = <" (join-bindings bindings) ">;\n")
                              "")
                          "            #binding-cells = <" (number->string binding-cells) ">;\n"
                          (if tapping-term
                              (string-append
                               "            tapping-term-ms = <" (number->string tapping-term) ">;\n")
                              "")
                          (if flavor
                              (string-append
                               "            flavor = \"" flavor "\";\n")
                              "")
                          "        };\n")))
                     actual-behaviors))
         "    };\n\n"))))

(define (generate-layer-bindings bindings)
  (let ((rows (length bindings)))
    (let loop ((i 0) (result ""))
      (if (= i rows)
          result
          (let ((row (list-ref bindings i)))
            (loop (+ i 1)
                  (string-append 
                   result 
                   "  "
                   (apply string-append
                          (map (lambda (binding)
                                 (if (equal? binding "")
                                     ""
                                     (string-append binding "  ")))
                               row))
                   "\n")))))))

(define (generate-keymap-layers config-layers)
  (display "Debugging layers: ") (display config-layers) (newline)
  (let ((actual-layers (car config-layers)))  ; Extract the actual layers list
    (string-append
     "    keymap {\n"
     "        compatible = \"zmk,keymap\";\n\n"
     (apply string-append
            (map (lambda (layer)
                   (let* ((name (car layer))
                          (props (cdr layer))
                          (layer-name (cadr (assoc 'name props)))
                          (comment (cadr (assoc 'comment props)))
                          (bindings (cadr (assoc 'bindings props))))
                     (string-append
                      "        " layer-name " {\n"
                      (if (not (equal? comment ""))
                          (string-append "            " comment "\n\n")
                          "")
                      "            bindings = <\n"
                      (generate-layer-bindings bindings)
                      "            >;\n"
                      "        };\n\n")))
                 actual-layers))
     "    };\n")))

(define (generate-keymap config output-file)
   ;; Print the config for debug
   (display "Config: ") (display config) (newline)
   
   (let ((out (open-output-file output-file)))
      ;; Generate header with configurable settings
      (display (generate-header config) out)
      
      ;; Generate modtap settings if present
      (if (assoc 'modtap-settings config)
          (let ((settings (cdr (assoc 'modtap-settings config))))
            (display "MT settings: ") (display settings) (newline)
            (display (generate-modtap-settings settings) out))
          (display "Warning: No modtap-settings found in config\n"))
      
      ;; Start root section
      (display (generate-root-begin) out)
      
      ;; Generate chosen section with matrix transform
      (display (generate-chosen config) out)
      
      ;; Generate combos if present
      (if (assoc 'combos config)
          (display (generate-combos (cdr (assoc 'combos config))) out)
          (display "" out))
      
      ;; Generate behaviors if present
      (if (assoc 'behaviors config)
          (display (generate-behaviors (cdr (assoc 'behaviors config))) out)
          (display "" out))
      
      ;; Generate keymap layers
      (if (assoc 'layers config)
          (display (generate-keymap-layers (cdr (assoc 'layers config))) out)
          (display "Warning: No layers found in config\n"))
      
      ;; End root section
      (display (generate-root-end) out)
      (close-output-port out)))

;; Main function - simplify it to handle the exact arguments we expect
(define (process-config-file input-file output-file)
  (display (string-append "Processing: " input-file " -> " output-file "\n"))
  (let* ((config-port (open-input-file input-file))
         (config (read config-port)))
    (close-input-port config-port)
    (generate-keymap config output-file)
    (display (string-append "ZMK config generated: " output-file "\n"))))

;; Start processing
(display "Starting ZMK config compiler\n")

;; Get the command line arguments
(let* ((raw-args (cdr (command-line)))  ; Skip program name
       (script-name (car raw-args))
       (args (cdr raw-args))  ; Skip script name
       (arg-count (length args)))
  
  (display "Args: ") (display args) (newline)
  
  (cond
   ;; No arguments provided
   ((= arg-count 0)
    (display "Usage: gxi corne.ss <input-file> [-o <output-file>]\n"))
   
   ;; Just input file
   ((= arg-count 1)
    (process-config-file (car args) output-filename))
   
   ;; Input file and -o flag but missing output file
   ((and (= arg-count 2) (string=? (cadr args) "-o"))
    (display "Error: Missing output filename after -o\n"))
   
   ;; Full arguments: input file, -o flag, and output file
   ((and (= arg-count 3) (string=? (cadr args) "-o"))
    (process-config-file (car args) (caddr args)))
   
   ;; Invalid arguments
   (else
    (display "Error: Invalid arguments\n")
    (display "Usage: gxi corne.ss <input-file> [-o <output-file>]\n"))))
