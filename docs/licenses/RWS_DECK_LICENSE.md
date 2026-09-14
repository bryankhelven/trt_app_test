# Rider-Waite-Smith Tarot Deck — License and Provenance

## Deck

- **Name:** Rider-Waite-Smith Tarot (also known as the Rider-Waite Tarot or the Waite-Smith Tarot)
- **Artist:** Pamela Colman Smith
- **Deviser / Author of accompanying system:** Arthur Edward Waite
- **Original Publisher:** Rider & Son (London)
- **Year of first publication:** 1909

## Why this artwork is public domain in the United States

The Rider-Waite-Smith deck was first published in 1909, and Pamela Colman Smith
(the illustrator) died in 1951. Under United States copyright law, works
published before 1929 are in the public domain in the US (this deck falls
under the pre-1929 published-work rule, and separately its term has fully
expired regardless of the life-plus-70-years rule for the artist). The
original 1909 printed cards therefore carry no copyright restrictions in the
United States, and faithful photographic reproductions of the original,
two-dimensional card scans do not create a new copyright (per the reasoning
in *Bridgeman Art Library v. Corel Corp.*, widely applied by Wikimedia
Commons to public-domain 2D reproductions).

This is exactly the reasoning Wikimedia Commons applies to its own hosted
scans of this deck, which are tagged `{{PD-old-100-1923}}` / `{{PD-US}}`.

## Source used for this project

All 78 card images plus source scans were sourced from **Wikimedia Commons**,
primarily:

- Category: [Rider-Waite tarot deck](https://commons.wikimedia.org/wiki/Category:Rider-Waite_tarot_deck)
- Major Arcana files follow the naming convention `RWS Tarot NN Name.jpg`
  (e.g. `RWS Tarot 00 Fool.jpg`, `RWS Tarot 01 Magician.jpg`, ...,
  `RWS Tarot 21 World.jpg`).
- Minor Arcana files follow the naming convention `<Suit><NN>.jpg` where
  `Suit` is `Wands`, `Cups`, `Swords`, or `Pents`, and `NN` is `01`=Ace,
  `02`-`10`=pip cards, `11`=Page, `12`=Knight, `13`=Queen, `14`=King (e.g.
  `Wands01.jpg`, `Cups11.jpg`, `Pents14.jpg`).

Files were fetched via Wikimedia Commons' `Special:FilePath` redirect
mechanism, which resolves a canonical filename directly to the current
full-resolution upload for that file.

The exact file page URL used for each of the 79 local assets, along with its
SHA-256 checksum and local path, is recorded in
[`docs/evidence/deck-provenance-manifest.json`](../evidence/deck-provenance-manifest.json).
Where an exact scan for a given card could not be retrieved after reasonable
effort, a substitute public-domain 1909 RWS scan of the *same* card from
Commons was used instead; any such substitution is called out explicitly in
the manifest entry for that card (`substitution_note` field).

## Card back artwork

`assets/decks/rws_v1/artwork/card_back.png` is **original artwork created
for this project** — a simple geometric indigo-to-teal gradient with a thin
gold border and mandala-style radial line pattern, generated programmatically
with Python + Pillow. It is not derived from any copyrighted card-back design
and is not a reproduction of any existing published tarot deck's back
artwork. It is licensed for use in this project the same as the rest of the
project's original code and assets.

## Manifest

See [`docs/evidence/deck-provenance-manifest.json`](../evidence/deck-provenance-manifest.json)
for the full per-file provenance record (79 entries: 78 cards + 1 card
back), each including `card_id`, `source`, `commons_file_url`, `license`,
`sha256`, and `local_path`.
