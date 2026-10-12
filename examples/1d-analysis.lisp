;;
;; This file is part of CLDS
;;
;; Description: here we describe what might go into a 1d data
;; analysis.
;;
;; 2026.10.12 : current verbs described below




;; step N:  generic function "publish".  This should take report contents (data, code, report) and publish pieces according to the template used.

(publish :report (list 'my-report-storage-location
		       'individually-specified)
	 :template '((PDF :style JASA)
		     (dynamic :style ('Shiny 'Quarto))
		     (MSWordX :style ('my-corp-template))
		     (MarkDown :storage-URL "file://path/to/")
		     (CorpCMS :style ('my-corp-template) :CMS ('Veeva)))
	 ;; the goal is to provide the components needed to convert
	 ;; content into a report-presentation style which can be
	 ;; deployed to a platform or the content saved.  Initially
	 ;; could be quarto, text, markdown, or similar
	 )

(report :code-toplevel-url (list "file://path/to/dir" "git://...." "http://....")
	:draft-text-url (list "file://path/to/dir" "git://...." "http://....")
	:llm-spec (list "N" (specs for access, submission point, answer point))
	;; what structure contains a minimal report contents?
	)

(execute-analysis :plan
		  :data-source
		  :components )

(data-validated ;; loads data or a "data pointer" in the case of a external data
      ;; location such as a database, data store, etc, provides the
      ;; tools to access values in a cases-by-variables with
      ;; independent or conditionally independent cases"
      :data-source-object (data-source :ID :URI :URL :access-type )
      :plan-description (create-plan-metadata
			 :outcome-variables-with-data-types/structures (list)
			 :dependent-variables-with-data-types/structures (list))

(plan ;; gives the data collection plan, metadata about the experiment
      ;; and data generating process, design characteristics,
      :specification
      :metadata-needs ))





;;;
;;; EXAMPLES

(publish
 :template (MarkDown :storage "file://path/to/toplevel/storage/")
 :report (report
	  (execute-analysis
	   :data-source (data-validated 
			    :data-source-object (data-source 
						 :URL "file://path/to/toplevel/project/"
						 :access-type 'FILE)
			    :plan-description (create-plan-metadata ()))
	   
	   :plan (plan-as-code
			 :specifications (list :dimensions (list NA '1d '2d 'nd)
					       :distribution (plan-distribution
							      :confidence-interval))
			 :metadata-needs (list NA)))))
	   


 
;; consider the following 2 datasets

(defvar dataset-1d-categorical (list "A" "B" "A" "B" "C" "B"))
(defvar dataset-1d-continous (list 1.2d 0.8d 1.0d 3.2d -2.9d))


;; then to analyse them....


(report (execute-analysis
	 :data-source (data-validated
		       :data-source-object
		       (data-source-variable dataset-1d-categorical)
		       :plan-description '1d-unlabeled-cat)
	 :plan (plan-as-code
		:specification  (list :dimensions '1d
				      :distribution 'categorical
				      :plots 't)
		:metadata-needs NA)))

;; should return a description of the data (3 levels, "A", "B", "C",
;; appropriate summary of frequencies, with recommended plots
;; dispatched on the data-source data type/structure



      
