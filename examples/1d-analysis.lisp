;;
;; This file is part of CL-DATASCIENCE
;;
;; Description: here we describe what might go into a 1d data
;; analysis.
;;
;; 2026.10.12 : current verbs described below


;; we consider a data science project to be an activity which in its
;; simplest form, a question is posed, information is collected, and
;; the information is analysed to address the question, hopefully
;; providing some improvement on what is known.
;;
;; Iterative loops and parallel activities can lead to improved
;; questions, additional or new data, possibly prematurely exiting the
;; activity and having it replaced by a reframed question and a
;; restart.




;; Consider a collection of measurements for which we would like to
;; know the general process characteristics and have a model of what
;; has happened and what could happen next.

 
;; take the following 2 datasets as a way forward:

(defvar dataset-1d-categorical (list "A" "B" "A" "B" "C" "B"))
(defvar dataset-1d-continous (list 1.2d 0.8d 1.0d 3.2d -2.9d))


;; 1. ensure that the collected data are appropriate for the problem
;;    at hand.
;;
;; one simple version would be to ensure that the data come from the
;; process being considered to address the question of interest.  So,
;; if the question is about the next possible value, and the data
;; originate probabilistically (next value would follow some random
;; process) then we would like to know the most common value, the most
;; likely value(s), and how wrong we could be.
;;
;; if the data is generated deterministically, following a clear
;; pattern or trend so that we KNOW what the next value will be, then
;; certain questions will be simple to answer, but other questions
;; would make no sense.

;; for example if we are interested in poetry or song structure, and
;; we know what the classic structure of the song would be, and the
;; categorical data gives the pattern but is only 6 parts of the
;; standard 8 parts, then we know that the next two will be "C" and
;; "B".

;; for example, if we know that the numerical values represent how
;; off-pitch a guitar string plays when strummed, then we expect that
;; the next value will be near to the current empirical average
;; (estimated mean).

;; (the randomness or deterministic-ness of the data could be the
;; otherway around -- these are just examples.)

;; so the data generating model will be important to know.  Under the
;; above conditions, it would be easy to ask about the next musical
;; stanza ("C").  but makes much less sense to talk about the chance
;; of a change... however we could still ask for tendencies, the
;; amount that the musical piece uses a particular stanza, and use the
;; overall information to classify the piece into the broader musical
;; corpus.

;; 2. understand what "appropriate" means, and how the approximation
;;    reduces confidence in the answers as final

;; 3. do the same for the planned data analysis approach

;; check assumptions of the data for the data analysis, and consider
;; if there is enough match ("art work, not science") that they will
;; work together

;; check assumptions of the question with the data analysis (and
;; considered possible results) and ensure there is "enough" match,


;; 4. execute the analyses, taking into account diagnostics which
;;    a. check fitness of the data,
;;    b. check fitness of the proposed data analysis strategy,
;;    c. evaluate the numerical interplay between them, and
;;    d. ensure the reasonableness of the conclusions which are
;;       wanted to be drawn from the results of executing on the data
;;       analysis strategy.


;; then what could the code look like to analyse them....?

;; considering side-effects which act on data through a data analysis
;; strategy to create a report:

(acknowledge/approve-activity :ask-boss T
			      :ask-finance nil
			      :need-resources (list (time 5 hours) 
						    (external-costs 0 chf)))
(plan-activity :name "musical stanza analysis" 
	       :data-sources (music :table (musical-patterns 'stanza) 
				    :database (music-colllections 1)))
(execute-activity (list (collect :data 'dataset-1d-categorical)
			(quality-check plan data)
			(analyse-data :using plan)))
(store-analysis
     music-stanza-activity
     'some-valid-URI-data-science-activity-repository)
(report-analysis music-stanza-activity
		 :title "type of music that was played based on stanza pattern"
		 :report-target 'Shiny)








;; considering a functional programming approach which considers no side-effects

;; NOT DONE YET

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











;;; EXPERIMENTS FOR FUNCTIONAL PROGRAMMING APPROACH, to define
;;; possible "verbs"




;; step N: generic function "publish".  This should take report
;; contents (data, code, report) and publish pieces according to the
;; template used.

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
	   


 


      
