;; title: Tokenized-Shipment-Receipts

(define-non-fungible-token shipment-receipt uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-shipment-not-found (err u102))
(define-constant err-invalid-milestone (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-shipment-completed (err u105))
(define-constant err-invalid-status (err u106))
(define-constant err-milestone-exists (err u107))
(define-constant err-invalid-participant (err u108))
(define-constant err-already-verified (err u109))
(define-constant err-dispute-exists (err u110))
(define-constant err-dispute-not-found (err u111))
(define-constant err-dispute-resolved (err u112))

(define-data-var shipment-id-nonce uint u0)

(define-map shipments
  uint
  {
    origin: (string-ascii 100),
    destination: (string-ascii 100),
    carrier: principal,
    shipper: principal,
    receiver: principal,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: (optional uint),
    value: uint,
    weight: uint
  }
)

(define-map shipment-milestones
  { shipment-id: uint, milestone-id: uint }
  {
    location: (string-ascii 100),
    description: (string-ascii 200),
    timestamp: uint,
    verified-by: principal,
    verified: bool
  }
)

(define-map milestone-count
  uint
  uint
)

(define-map authorized-carriers
  principal
  bool
)

(define-map authorized-verifiers
  principal
  bool
)

(define-map shipment-metadata
  uint
  {
    product-type: (string-ascii 50),
    quantity: uint,
    temperature-controlled: bool,
    fragile: bool,
    customs-cleared: bool
  }
)

(define-map shipment-disputes
  uint
  {
    raised-by: principal,
    reason: (string-ascii 500),
    raised-at: uint,
    resolved: bool,
    resolution: (optional (string-ascii 500)),
    resolved-at: (optional uint),
    resolved-by: (optional principal)
  }
)

(define-read-only (get-shipment (shipment-id uint))
  (map-get? shipments shipment-id)
)

(define-read-only (get-milestone (shipment-id uint) (milestone-id uint))
  (map-get? shipment-milestones { shipment-id: shipment-id, milestone-id: milestone-id })
)

(define-read-only (get-milestone-count (shipment-id uint))
  (default-to u0 (map-get? milestone-count shipment-id))
)

(define-read-only (get-owner (shipment-id uint))
  (ok (nft-get-owner? shipment-receipt shipment-id))
)

(define-read-only (is-authorized-carrier (carrier principal))
  (default-to false (map-get? authorized-carriers carrier))
)

(define-read-only (is-authorized-verifier (verifier principal))
  (default-to false (map-get? authorized-verifiers verifier))
)

(define-read-only (get-shipment-metadata (shipment-id uint))
  (map-get? shipment-metadata shipment-id)
)

(define-read-only (get-last-shipment-id)
  (ok (var-get shipment-id-nonce))
)

(define-read-only (get-dispute (shipment-id uint))
  (map-get? shipment-disputes shipment-id)
)

(define-public (authorize-carrier (carrier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-carriers carrier true))
  )
)

(define-public (revoke-carrier (carrier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-carriers carrier false))
  )
)

(define-public (authorize-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers verifier true))
  )
)

(define-public (revoke-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set authorized-verifiers verifier false))
  )
)

(define-public (create-shipment 
  (origin (string-ascii 100))
  (destination (string-ascii 100))
  (carrier principal)
  (receiver principal)
  (value uint)
  (weight uint)
  (product-type (string-ascii 50))
  (quantity uint)
  (temperature-controlled bool)
  (fragile bool)
)
  (let
    (
      (new-id (+ (var-get shipment-id-nonce) u1))
      (current-block stacks-block-height)
    )
    (asserts! (is-authorized-carrier carrier) err-unauthorized)
    (try! (nft-mint? shipment-receipt new-id tx-sender))
    (map-set shipments new-id {
      origin: origin,
      destination: destination,
      carrier: carrier,
      shipper: tx-sender,
      receiver: receiver,
      status: "created",
      created-at: current-block,
      completed-at: none,
      value: value,
      weight: weight
    })
    (map-set shipment-metadata new-id {
      product-type: product-type,
      quantity: quantity,
      temperature-controlled: temperature-controlled,
      fragile: fragile,
      customs-cleared: false
    })
    (map-set milestone-count new-id u0)
    (var-set shipment-id-nonce new-id)
    (ok new-id)
  )
)

(define-public (add-milestone
  (shipment-id uint)
  (location (string-ascii 100))
  (description (string-ascii 200))
)
  (let
    (
      (shipment (unwrap! (map-get? shipments shipment-id) err-shipment-not-found))
      (current-milestone-count (get-milestone-count shipment-id))
      (new-milestone-id (+ current-milestone-count u1))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get carrier shipment)) err-unauthorized)
    (asserts! (not (is-eq (get status shipment) "completed")) err-shipment-completed)
    (map-set shipment-milestones 
      { shipment-id: shipment-id, milestone-id: new-milestone-id }
      {
        location: location,
        description: description,
        timestamp: current-block,
        verified-by: tx-sender,
        verified: false
      }
    )
    (map-set milestone-count shipment-id new-milestone-id)
    (ok new-milestone-id)
  )
)

(define-public (verify-milestone
  (shipment-id uint)
  (milestone-id uint)
)
  (let
    (
      (milestone (unwrap! (map-get? shipment-milestones { shipment-id: shipment-id, milestone-id: milestone-id }) err-invalid-milestone))
    )
    (asserts! (is-authorized-verifier tx-sender) err-unauthorized)
    (asserts! (not (get verified milestone)) err-already-verified)
    (ok (map-set shipment-milestones 
      { shipment-id: shipment-id, milestone-id: milestone-id }
      (merge milestone { verified: true, verified-by: tx-sender })
    ))
  )
)

(define-public (update-shipment-status
  (shipment-id uint)
  (new-status (string-ascii 20))
)
  (let
    (
      (shipment (unwrap! (map-get? shipments shipment-id) err-shipment-not-found))
    )
    (asserts! (is-eq tx-sender (get carrier shipment)) err-unauthorized)
    (ok (map-set shipments shipment-id (merge shipment { status: new-status })))
  )
)

(define-public (complete-shipment (shipment-id uint))
  (let
    (
      (shipment (unwrap! (map-get? shipments shipment-id) err-shipment-not-found))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get carrier shipment)) err-unauthorized)
    (asserts! (not (is-eq (get status shipment) "completed")) err-shipment-completed)
    (map-set shipments shipment-id 
      (merge shipment { 
        status: "completed", 
        completed-at: (some current-block) 
      })
    )
    (try! (nft-transfer? shipment-receipt shipment-id (get shipper shipment) (get receiver shipment)))
    (ok true)
  )
)

(define-public (transfer-shipment
  (shipment-id uint)
  (sender principal)
  (recipient principal)
)
  (let
    (
      (shipment (unwrap! (map-get? shipments shipment-id) err-shipment-not-found))
    )
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (asserts! (not (is-eq (get status shipment) "completed")) err-shipment-completed)
    (try! (nft-transfer? shipment-receipt shipment-id sender recipient))
    (ok true)
  )
)

(define-public (mark-customs-cleared (shipment-id uint))
  (let
    (
      (metadata (unwrap! (map-get? shipment-metadata shipment-id) err-shipment-not-found))
    )
    (asserts! (is-authorized-verifier tx-sender) err-unauthorized)
    (ok (map-set shipment-metadata shipment-id 
      (merge metadata { customs-cleared: true })
    ))
  )
)

(define-public (emergency-transfer
  (shipment-id uint)
  (new-owner principal)
)
  (let
    (
      (current-owner (unwrap! (nft-get-owner? shipment-receipt shipment-id) err-shipment-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (nft-transfer? shipment-receipt shipment-id current-owner new-owner))
    (ok true)
  )
)

(define-public (raise-dispute
  (shipment-id uint)
  (reason (string-ascii 500))
)
  (let
    (
      (shipment (unwrap! (map-get? shipments shipment-id) err-shipment-not-found))
      (current-block stacks-block-height)
      (existing-dispute (map-get? shipment-disputes shipment-id))
    )
    (asserts! (is-none existing-dispute) err-dispute-exists)
    (asserts! 
      (or 
        (is-eq tx-sender (get shipper shipment))
        (is-eq tx-sender (get receiver shipment))
      ) 
      err-unauthorized
    )
    (ok (map-set shipment-disputes shipment-id {
      raised-by: tx-sender,
      reason: reason,
      raised-at: current-block,
      resolved: false,
      resolution: none,
      resolved-at: none,
      resolved-by: none
    }))
  )
)

(define-public (resolve-dispute
  (shipment-id uint)
  (resolution (string-ascii 500))
)
  (let
    (
      (dispute (unwrap! (map-get? shipment-disputes shipment-id) err-dispute-not-found))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get resolved dispute)) err-dispute-resolved)
    (ok (map-set shipment-disputes shipment-id 
      (merge dispute {
        resolved: true,
        resolution: (some resolution),
        resolved-at: (some current-block),
        resolved-by: (some tx-sender)
      })
    ))
  )
)
