(import ../src/ffi)
(use judge)

(let [char-ptr-ptr (ffi/write :string "hello")]
  (test (type char-ptr-ptr) :buffer)                    #char** as address of address buffer
  (comment (test (ffi/deref-c-string-ptr char-ptr-ptr) "X\xFC\xB6*"))
  (let [char-ptr (ffi/read :ptr char-ptr-ptr)]
    (test (type char-ptr) :pointer)                     #char *
    (test (ffi/deref-c-string-ptr char-ptr) "hello")))

(let [char-ptr (ffi/write @[:char 6] (string/bytes "hello\0"))]
  (test char-ptr @"hello\0")
  (test (type char-ptr) :buffer)                        #char * as address buffer
  (test (ffi/deref-c-string-ptr char-ptr) "hello")      # works too!
  (let [char-ptr-ptr (ffi/write :ptr char-ptr)]
    (test (type char-ptr-ptr) :buffer)                  #char ** as address of address buffer
    (let [char-ptr2 (ffi/read :ptr char-ptr-ptr)]
      (test (type char-ptr2) :pointer)                  #char *
      (test (ffi/deref-c-string-ptr char-ptr2) "hello"))))
