;; School Collaboration Spaces - Decentralized identity-based collaboration

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-member (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-invalid-data (err u105))
(define-constant err-not-active (err u106))
(define-constant err-insufficient-reputation (err u107))

;; Data Variables
(define-data-var total-spaces uint u0)
(define-data-var total-schools uint u0)
(define-data-var total-resources uint u0)
(define-data-var total-messages uint u0)
(define-data-var total-projects uint u0)