test_that("kastore_version() works", {
  v <- kastore_version()
  expect_true(is.integer(v))
  expect_equal(names(v), c("major", "minor", "patch"))
  expect_identical(v, c(major = 2L, minor = 1L, patch = 3L))
})

test_that("tskit_version() works", {
  v <- tskit_version()
  expect_true(is.integer(v))
  expect_equal(names(v), c("major", "minor", "patch"))
})

test_that("tsk_bug_assert() works", {
  # jarl-ignore internal_function:  it's just a test
  expect_error(RcppTskit:::test_tsk_bug_assert_c())
  # jarl-ignore internal_function:  it's just a test
  expect_error(RcppTskit:::test_tsk_bug_assert_cpp())
})

test_that("tsk_trace_error() works", {
  t <- "You have to compile with -DTSK_TRACE_ERRORS to run these tests. See src/Makevars.in."
  # jarl-ignore internal_function:  it's just a test
  skip_if_not(RcppTskit:::tsk_trace_errors_defined(), t)
  # jarl-ignore internal_function:  it's just a test
  expect_warning(RcppTskit:::test_tsk_trace_error_c())
  # jarl-ignore internal_function:  it's just a test
  expect_warning(RcppTskit:::test_tsk_trace_error_cpp())
})

test_that("validate_options() branches are covered", {
  # jarl-ignore internal_function: it's just a test
  expect_equal(RcppTskit:::test_validate_options(0L, 0L), 0L)

  # negative options branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(-1L, 0L),
    regexp = "test_validate_options does not support negative options"
  )

  # unsupported bits branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(1L, 0L),
    regexp = "test_validate_options only supports options"
  )

  # non-zero supported flags branch
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_validate_options(1L, 1L),
    regexp = "test_validate_options does not support non-zero options"
  )
})

test_that("tsk_flags_t conversion rejects values outside the R integer range", {
  # jarl-ignore internal_function: it's just a test
  expect_identical(
    RcppTskit:::test_rtsk_wrap_tsk_flags_as_int(.Machine$integer.max),
    .Machine$integer.max
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_flags_as_int(
      as.numeric(.Machine$integer.max) + 1
    ),
    regexp = paste0(
      "cannot represent tsk_flags_t value 2147483648 as a C\\+\\+ int ",
      "\\(and hence as an R integer\\); maximum supported value is 2147483647"
    )
  )

  invalid_tsk_flags <- c(-1, 1.5, Inf, NaN, 2^32)
  for (value in invalid_tsk_flags) {
    # jarl-ignore internal_function: it's just a test
    expect_error(
      RcppTskit:::test_rtsk_wrap_tsk_flags_as_int(value),
      regexp = "value must be an integer within the tsk_flags_t range"
    )
  }
})

test_that("R-side integer and row-index validators cover message branches", {
  # jarl-ignore internal_function: it's just a test
  expect_no_error(RcppTskit:::validate_integer_scalar_arg(1, "x"))
  # jarl-ignore internal_function: it's just a test
  expect_equal(
    RcppTskit:::validate_integer_scalar_arg(1L, "x", strict = TRUE),
    1L
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(1, "x", strict = TRUE),
    regexp = "x must be a non-NA integer scalar within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(1.5, "x"),
    regexp = "x must be a non-NA integer scalar within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(
      as.numeric(.Machine$integer.max) + 1,
      "x"
    ),
    regexp = "x must be a non-NA integer scalar within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(1L, "x", minimum = 2L),
    regexp = "x must be a non-NA integer scalar within 32-bit range \\(>= 2\\)!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(
      -as.numeric(.Machine$integer.max) - 2,
      "x"
    ),
    regexp = "x must be a non-NA integer scalar within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_integer_scalar_arg(NULL, "x"),
    regexp = "x cannot be NULL\\."
  )
  # jarl-ignore internal_function: it's just a test
  expect_no_error(
    RcppTskit:::validate_optional_integer_vector_arg(c(1, 2, 3), "ids")
  )
  # jarl-ignore internal_function: it's just a test
  expect_equal(
    RcppTskit:::validate_optional_integer_vector_arg(c(1, 2, 3), "ids"),
    invisible(c(1L, 2L, 3L))
  )
  # jarl-ignore internal_function: it's just a test
  expect_no_error(
    RcppTskit:::validate_optional_integer_vector_arg(c(1.0, 2.0), "ids")
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_optional_integer_vector_arg(
      c(1, 2, 3),
      "ids",
      strict = TRUE
    ),
    regexp = "ids must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_optional_integer_vector_arg(c(1, 2.5), "ids"),
    regexp = "ids must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::validate_optional_integer_vector_arg(
      c(as.numeric(.Machine$integer.max) + 1),
      "ids"
    ),
    regexp = "ids must be NULL or an integer vector with no NA values within 32-bit range!"
  )
  # jarl-ignore internal_function: it's just a test
  expect_no_error(RcppTskit:::validate_row_index(NULL, allow_null = TRUE))
})

test_that("optional numeric-vector validator enforces type and length", {
  # jarl-ignore internal_function: it's just a test
  validator <- RcppTskit:::validate_optional_numeric_vector_arg

  expect_no_error(validator(NULL, "x", lengths = c(1L, 2L)))
  expect_no_error(validator(1, "x", lengths = c(1L, 2L)))
  expect_no_error(validator(c(1L, 2L), "x", lengths = c(1L, 2L)))
  expect_no_error(validator(c(-Inf, Inf), "x", lengths = 2L))
  expect_no_error(validator(numeric(), "x"))

  invalid <- list(
    "1",
    TRUE,
    1 + 1i,
    matrix(1:2, nrow = 1),
    array(1:2, dim = c(1, 1, 2)),
    NA_real_,
    NaN,
    numeric(),
    1:3
  )
  for (value in invalid) {
    expect_error(
      validator(value, "x", lengths = c(1L, 2L)),
      "x must be NULL or a numeric vector with no NA values!"
    )
  }

  expect_error(
    validator(
      1:3,
      "x",
      lengths = c(1L, 2L),
      error_message = "custom message"
    ),
    "custom message"
  )
})

test_that("numeric closeness matches NumPy semantics for finite values and infinities", {
  # jarl-ignore internal_function: it's just a test
  is_close <- RcppTskit:::numeric_values_are_close

  tolerance <- 1e-08 + 1e-05 * 3
  expect_identical(
    is_close(c(3, 3 + tolerance / 2, 3 + tolerance * 2), 3),
    c(TRUE, TRUE, FALSE)
  )
  expect_identical(is_close(c(1, Inf, -Inf), Inf), c(FALSE, TRUE, FALSE))
  expect_identical(is_close(c(1, Inf, -Inf), -Inf), c(FALSE, FALSE, TRUE))
  expect_identical(is_close(c(NA_real_, NaN), 0), c(FALSE, FALSE))
  expect_identical(is_close(numeric(), 0), logical())
})

test_that("rtsk_wrap_tsk_size_t_as_integer64() works", {
  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("0")
  expect_true(bit64::is.integer64(x))
  expect_equal(x, bit64::as.integer64("0"))

  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("42")
  expect_true(bit64::is.integer64(x))
  expect_equal(as.character(x), "42")

  # max signed 64-bit integer (limit of bit64::integer64)
  max_i64 <- "9223372036854775807"
  # jarl-ignore internal_function: it's just a test
  x <- RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64(max_i64)
  expect_true(bit64::is.integer64(x))
  expect_equal(as.character(x), max_i64)

  # first value above signed 64-bit range
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("9223372036854775808"),
    regexp = "exceeds bit64::integer64 maximum"
  )

  # invalid numeric format
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("not_a_number"),
    regexp = "base-10 unsigned integer string"
  )

  # parsed prefix only; remaining characters should fail strict parse check
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("123abc"),
    regexp = "base-10 unsigned integer string"
  )

  # force range-check branch (test-only path)
  # jarl-ignore internal_function: it's just a test
  expect_error(
    RcppTskit:::test_rtsk_wrap_tsk_size_t_as_integer64("1", TRUE),
    regexp = "value is out of range for tsk_size_t"
  )
})
