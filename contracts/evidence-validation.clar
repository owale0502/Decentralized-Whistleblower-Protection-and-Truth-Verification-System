;; Evidence Validation Contract
;; Uses cryptographic proofs to verify document authenticity without revealing sources

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-INPUT (err u301))
(define-constant ERR-EVIDENCE-NOT-FOUND (err u302))
(define-constant ERR-ALREADY-VALIDATED (err u303))
(define-constant ERR-VALIDATION-FAILED (err u304))

;; Data Variables
(define-data-var next-evidence-id uint u1)
(define-data-var validation-threshold uint u3)
(define-data-var total-evidence-items uint u0)

;; Data Maps
(define-map evidence-records
  { evidence-id: uint }
  {
    document-hash: (buff 32),
    report-id: uint,
    evidence-type: (string-ascii 50),
    timestamp: uint,
    validation-status: (string-ascii 20),
    validation-count: uint,
    integrity-proof: (buff 64)
  }
)

(define-map validation-proofs
  { evidence-id: uint, validator: principal }
  {
    proof-hash: (buff 32),
    validation-method: (string-ascii 30),
    confidence-score: uint,
    validated-at: uint
  }
)

(define-map evidence-metadata
  { evidence-id: uint }
  {
    file-size: uint,
    mime-type: (string-ascii 50),
    creation-timestamp: uint,
    source-verification: (buff 32)
  }
)

(define-map validator-credentials
  { validator: principal }
  {
    reputation-score: uint,
    validations-performed: uint,
    accuracy-rate: uint,
    certified: bool
  }
)

(define-map evidence-chains
  { parent-evidence-id: uint, child-evidence-id: uint }
  { relationship-type: (string-ascii 30), verified: bool }
)

;; Public Functions

;; Submit evidence for validation
(define-public (submit-evidence (document-hash (buff 32)) (report-id uint) (evidence-type (string-ascii 50)) (integrity-proof (buff 64)))
  (let
    (
      (evidence-id (var-get next-evidence-id))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (len document-hash) u0) ERR-INVALID-INPUT)
    (asserts! (> report-id u0) ERR-INVALID-INPUT)
    (asserts! (> (len evidence-type) u0) ERR-INVALID-INPUT)
    (asserts! (> (len integrity-proof) u0) ERR-INVALID-INPUT)

    (map-set evidence-records
      { evidence-id: evidence-id }
      {
        document-hash: document-hash,
        report-id: report-id,
        evidence-type: evidence-type,
        timestamp: current-time,
        validation-status: "pending",
        validation-count: u0,
        integrity-proof: integrity-proof
      }
    )

    (var-set next-evidence-id (+ evidence-id u1))
    (var-set total-evidence-items (+ (var-get total-evidence-items) u1))

    (ok evidence-id)
  )
)

;; Add metadata to evidence
(define-public (add-evidence-metadata (evidence-id uint) (file-size uint) (mime-type (string-ascii 50)) (creation-timestamp uint) (source-verification (buff 32)))
  (let
    (
      (evidence (unwrap! (map-get? evidence-records { evidence-id: evidence-id }) ERR-EVIDENCE-NOT-FOUND))
    )
    (asserts! (> file-size u0) ERR-INVALID-INPUT)
    (asserts! (> (len mime-type) u0) ERR-INVALID-INPUT)
    (asserts! (> creation-timestamp u0) ERR-INVALID-INPUT)

    (map-set evidence-metadata
      { evidence-id: evidence-id }
      {
        file-size: file-size,
        mime-type: mime-type,
        creation-timestamp: creation-timestamp,
        source-verification: source-verification
      }
    )

    (ok true)
  )
)

;; Validate evidence
(define-public (validate-evidence (evidence-id uint) (proof-hash (buff 32)) (validation-method (string-ascii 30)) (confidence-score uint))
  (let
    (
      (evidence (unwrap! (map-get? evidence-records { evidence-id: evidence-id }) ERR-EVIDENCE-NOT-FOUND))
      (current-validation-count (get validation-count evidence))
    )
    (asserts! (> (len proof-hash) u0) ERR-INVALID-INPUT)
    (asserts! (> (len validation-method) u0) ERR-INVALID-INPUT)
    (asserts! (and (>= confidence-score u0) (<= confidence-score u100)) ERR-INVALID-INPUT)

    ;; Check if validator is authorized
    (asserts! (is-validator-certified tx-sender) ERR-NOT-AUTHORIZED)

    ;; Record validation proof
    (map-set validation-proofs
      { evidence-id: evidence-id, validator: tx-sender }
      {
        proof-hash: proof-hash,
        validation-method: validation-method,
        confidence-score: confidence-score,
        validated-at: block-height
      }
    )

    ;; Update evidence validation count
    (map-set evidence-records
      { evidence-id: evidence-id }
      (merge evidence { validation-count: (+ current-validation-count u1) })
    )

    ;; Update validator credentials
    (update-validator-stats tx-sender)

    ;; Check if validation threshold is met
    (if (>= (+ current-validation-count u1) (var-get validation-threshold))
      (begin
        (map-set evidence-records
          { evidence-id: evidence-id }
          (merge evidence {
            validation-status: "validated",
            validation-count: (+ current-validation-count u1)
          })
        )
        (ok "validated")
      )
      (ok "pending")
    )
  )
)

;; Link evidence items in a chain
(define-public (link-evidence (parent-evidence-id uint) (child-evidence-id uint) (relationship-type (string-ascii 30)))
  (let
    (
      (parent-evidence (unwrap! (map-get? evidence-records { evidence-id: parent-evidence-id }) ERR-EVIDENCE-NOT-FOUND))
      (child-evidence (unwrap! (map-get? evidence-records { evidence-id: child-evidence-id }) ERR-EVIDENCE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len relationship-type) u0) ERR-INVALID-INPUT)

    (map-set evidence-chains
      { parent-evidence-id: parent-evidence-id, child-evidence-id: child-evidence-id }
      { relationship-type: relationship-type, verified: false }
    )

    (ok true)
  )
)

;; Certify a validator
(define-public (certify-validator (validator principal) (initial-reputation uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= initial-reputation u100) ERR-INVALID-INPUT)

    (map-set validator-credentials
      { validator: validator }
      {
        reputation-score: initial-reputation,
        validations-performed: u0,
        accuracy-rate: u100,
        certified: true
      }
    )

    (ok true)
  )
)

;; Challenge evidence validation
(define-public (challenge-validation (evidence-id uint) (challenge-proof (buff 32)) (reason (string-ascii 200)))
  (let
    (
      (evidence (unwrap! (map-get? evidence-records { evidence-id: evidence-id }) ERR-EVIDENCE-NOT-FOUND))
    )
    (asserts! (> (len challenge-proof) u0) ERR-INVALID-INPUT)
    (asserts! (> (len reason) u0) ERR-INVALID-INPUT)

    ;; Reset validation status for review
    (map-set evidence-records
      { evidence-id: evidence-id }
      (merge evidence { validation-status: "challenged" })
    )

    (ok true)
  )
)

;; Private Functions

;; Update validator statistics
(define-private (update-validator-stats (validator principal))
  (match (map-get? validator-credentials { validator: validator })
    existing-creds
    (map-set validator-credentials
      { validator: validator }
      (merge existing-creds {
        validations-performed: (+ (get validations-performed existing-creds) u1)
      })
    )
    false
  )
)

;; Read-only Functions

;; Get evidence record
(define-read-only (get-evidence (evidence-id uint))
  (map-get? evidence-records { evidence-id: evidence-id })
)

;; Get evidence metadata
(define-read-only (get-evidence-metadata (evidence-id uint))
  (map-get? evidence-metadata { evidence-id: evidence-id })
)

;; Get validation proof
(define-read-only (get-validation-proof (evidence-id uint) (validator principal))
  (map-get? validation-proofs { evidence-id: evidence-id, validator: validator })
)

;; Check if validator is certified
(define-read-only (is-validator-certified (validator principal))
  (match (map-get? validator-credentials { validator: validator })
    creds (get certified creds)
    false
  )
)

;; Get validator credentials
(define-read-only (get-validator-credentials (validator principal))
  (map-get? validator-credentials { validator: validator })
)

;; Get evidence chain link
(define-read-only (get-evidence-link (parent-evidence-id uint) (child-evidence-id uint))
  (map-get? evidence-chains { parent-evidence-id: parent-evidence-id, child-evidence-id: child-evidence-id })
)

;; Get total evidence items
(define-read-only (get-total-evidence-items)
  (var-get total-evidence-items)
)

;; Get validation threshold
(define-read-only (get-validation-threshold)
  (var-get validation-threshold)
)
