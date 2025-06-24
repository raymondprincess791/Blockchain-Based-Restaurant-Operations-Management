;; Inventory Optimization Contract
;; Manages and optimizes restaurant food inventory

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_QUANTITY (err u201))
(define-constant ERR_ITEM_NOT_FOUND (err u202))
(define-constant ERR_INSUFFICIENT_STOCK (err u203))

;; Data maps
(define-map inventory-items uint {
    name: (string-ascii 50),
    current-stock: uint,
    min-threshold: uint,
    max-capacity: uint,
    unit-cost: uint,
    expiry-date: uint,
    restaurant-id: uint
})

(define-map restaurant-managers uint principal)
(define-data-var next-item-id uint u1)

;; Public functions
(define-public (add-inventory-item
    (name (string-ascii 50))
    (initial-stock uint)
    (min-threshold uint)
    (max-capacity uint)
    (unit-cost uint)
    (expiry-date uint)
    (restaurant-id uint))
    (let ((item-id (var-get next-item-id)))
        (asserts! (> initial-stock u0) ERR_INVALID_QUANTITY)
        (asserts! (<= initial-stock max-capacity) ERR_INVALID_QUANTITY)
        (map-set inventory-items item-id {
            name: name,
            current-stock: initial-stock,
            min-threshold: min-threshold,
            max-capacity: max-capacity,
            unit-cost: unit-cost,
            expiry-date: expiry-date,
            restaurant-id: restaurant-id
        })
        (var-set next-item-id (+ item-id u1))
        (ok item-id)
    )
)

(define-public (update-stock (item-id uint) (new-quantity uint))
    (match (map-get? inventory-items item-id)
        item (begin
            (asserts! (<= new-quantity (get max-capacity item)) ERR_INVALID_QUANTITY)
            (map-set inventory-items item-id (merge item { current-stock: new-quantity }))
            (ok true)
        )
        ERR_ITEM_NOT_FOUND
    )
)

(define-public (consume-inventory (item-id uint) (quantity uint))
    (match (map-get? inventory-items item-id)
        item (begin
            (asserts! (>= (get current-stock item) quantity) ERR_INSUFFICIENT_STOCK)
            (map-set inventory-items item-id
                (merge item { current-stock: (- (get current-stock item) quantity) }))
            (ok true)
        )
        ERR_ITEM_NOT_FOUND
    )
)

;; Read-only functions
(define-read-only (get-inventory-item (item-id uint))
    (map-get? inventory-items item-id)
)

(define-read-only (needs-restock (item-id uint))
    (match (map-get? inventory-items item-id)
        item (ok (<= (get current-stock item) (get min-threshold item)))
        ERR_ITEM_NOT_FOUND
    )
)

(define-read-only (get-total-items)
    (var-get next-item-id)
)
