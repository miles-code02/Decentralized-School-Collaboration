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

;; Data Maps
(define-map schools
    { school-id: uint }
    {
        name: (string-ascii 100),
        admin: principal,
        verified: bool
    }
)

(define-map collaboration-spaces
    { space-id: uint }
    {
        name: (string-ascii 100),
        creator: principal,
        school-id: uint,
        active: bool
    }
)

(define-map space-members
    { space-id: uint, member: principal }
    {
        joined: bool,
        join-time: uint,
        school-id: uint
    }
)

(define-map school-members
    { school-id: uint, member: principal }
    { verified: bool, role: (string-ascii 20) }
)

(define-map resources
    { resource-id: uint }
    {
        title: (string-ascii 100),
        creator: principal,
        space-id: uint,
        shared: bool,
        timestamp: uint
    }
)

(define-map space-messages
    { message-id: uint }
    {
        content: (string-ascii 500),
        sender: principal,
        space-id: uint,
        timestamp: uint
    }
)

(define-map user-reputation
    { user: principal, school-id: uint }
    {
        score: uint,
        contributions: uint
    }
)

(define-map projects
    { project-id: uint }
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        space-id: uint,
        owner: principal,
        status: (string-ascii 20),
        created-at: uint
    }
)

(define-map project-members
    { project-id: uint, member: principal }
    {
        role: (string-ascii 20),
        joined-at: uint
    }
)

;; Read-only functions
(define-read-only (get-school (school-id uint))
    (map-get? schools { school-id: school-id })
)

(define-read-only (get-space (space-id uint))
    (map-get? collaboration-spaces { space-id: space-id })
)

(define-read-only (is-space-member (space-id uint) (member principal))
    (default-to false (get joined (map-get? space-members { space-id: space-id, member: member })))
)

(define-read-only (is-school-member (school-id uint) (member principal))
    (is-some (map-get? school-members { school-id: school-id, member: member }))
)

(define-read-only (get-total-spaces)
    (ok (var-get total-spaces))
)

(define-read-only (get-total-schools)
    (ok (var-get total-schools))
)

(define-read-only (get-resource (resource-id uint))
    (map-get? resources { resource-id: resource-id })
)

(define-read-only (get-user-reputation (user principal) (school-id uint))
    (default-to { score: u0, contributions: u0 }
        (map-get? user-reputation { user: user, school-id: school-id }))
)

(define-read-only (get-project (project-id uint))
    (map-get? projects { project-id: project-id })
)

(define-read-only (is-project-member (project-id uint) (member principal))
    (is-some (map-get? project-members { project-id: project-id, member: member }))
)

(define-read-only (get-message (message-id uint))
    (map-get? space-messages { message-id: message-id })
)

(define-read-only (get-total-resources)
    (ok (var-get total-resources))
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (register-school (name (string-ascii 100)))
    (let ((new-school-id (+ (var-get total-schools) u1)))
        (map-set schools
            { school-id: new-school-id }
            { name: name, admin: tx-sender, verified: true }
        )
        (map-set school-members
            { school-id: new-school-id, member: tx-sender }
            { verified: true, role: "admin" }
        )
        (var-set total-schools new-school-id)
        (ok new-school-id)
    )
)

;; #[allow(unchecked_data)]
(define-public (add-school-member (school-id uint) (member principal) (role (string-ascii 20)))
    (let ((school (unwrap! (map-get? schools { school-id: school-id }) err-not-found)))
        (asserts! (is-eq tx-sender (get admin school)) err-unauthorized)
        (ok (map-set school-members
            { school-id: school-id, member: member }
            { verified: true, role: role }
        ))
    )
)

;; #[allow(unchecked_data)]
(define-public (create-collaboration-space (name (string-ascii 100)) (school-id uint))
    (let (
        (new-space-id (+ (var-get total-spaces) u1))
        (is-member (is-school-member school-id tx-sender))
    )
        (asserts! is-member err-unauthorized)
        (map-set collaboration-spaces
            { space-id: new-space-id }
            { name: name, creator: tx-sender, school-id: school-id, active: true }
        )
        (map-set space-members
            { space-id: new-space-id, member: tx-sender }
            { joined: true, join-time: stacks-block-height, school-id: school-id }
        )
        (var-set total-spaces new-space-id)
        (ok new-space-id)
    )
)

;; #[allow(unchecked_data)]
(define-public (join-space (space-id uint) (school-id uint))
    (let (
        (space (unwrap! (map-get? collaboration-spaces { space-id: space-id }) err-not-found))
        (is-member (is-school-member school-id tx-sender))
        (already-joined (is-space-member space-id tx-sender))
    )
        (asserts! is-member err-unauthorized)
        (asserts! (not already-joined) err-already-member)
        (asserts! (get active space) err-not-found)
        (ok (map-set space-members
            { space-id: space-id, member: tx-sender }
            { joined: true, join-time: stacks-block-height, school-id: school-id }
        ))
    )
)

;; #[allow(unchecked_data)]
(define-public (share-resource (title (string-ascii 100)) (space-id uint))
    (let (
        (new-resource-id (+ (var-get total-resources) u1))
        (space (unwrap! (map-get? collaboration-spaces { space-id: space-id }) err-not-found))
        (is-member (is-space-member space-id tx-sender))
    )
        (asserts! is-member err-unauthorized)
        (asserts! (get active space) err-not-active)
        (map-set resources
            { resource-id: new-resource-id }
            {
                title: title,
                creator: tx-sender,
                space-id: space-id,
                shared: true,
                timestamp: stacks-block-height
            }
        )
        (var-set total-resources new-resource-id)
        (begin
            (unwrap-panic (increment-reputation tx-sender (get school-id space)))
            (ok new-resource-id)
        )
    )
)

;; #[allow(unchecked_data)]
(define-public (post-message (content (string-ascii 500)) (space-id uint))
    (let (
        (new-message-id (+ (var-get total-messages) u1))
        (space (unwrap! (map-get? collaboration-spaces { space-id: space-id }) err-not-found))
        (is-member (is-space-member space-id tx-sender))
    )
        (asserts! is-member err-unauthorized)
        (asserts! (get active space) err-not-active)
        (map-set space-messages
            { message-id: new-message-id }
            {
                content: content,
                sender: tx-sender,
                space-id: space-id,
                timestamp: stacks-block-height
            }
        )
        (var-set total-messages new-message-id)
        (ok new-message-id)
    )
)