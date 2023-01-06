# Post Review Github Action

Post reviews to a ReviewBoard instance, useful to report CI issues to the review.

Runs on `ubuntu` and `macos`.

## Usage

To add a comment to a review:
```yaml
- name: Post a review
  id: post-review
  uses: SMillerDev/reviewboard-action@main
  with:
    token: "SOME_TOKEN"
    url: https://reviews.lunr.nl
    action: comment
    header: 'Some header'
    footer: 'And a footer'
```

To publish a review:
```yaml
- name: Post a review
  id: post-review
  uses: SMillerDev/reviewboard-action@main
  with:
    token: "SOME_TOKEN"
    url: https://reviews.lunr.nl
    action: publish
```