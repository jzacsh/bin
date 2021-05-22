#!/usr/bin/env -S deno run  --allow-run --allow-net --allow-read
/**
 * Checks whether version of golang is the most up to date.
 *
 * Uses golang source repo's version tags to determine this, comparing to
 * `go version` output.
 */
// TODO(jzacsh) rm '.ts' extension on this file once deno solves this:
// https://github.com/denoland/deno/issues/5088

const { args, env, exit, readTextFile } = Deno;

const DEBUGGING = false;

/**
 * Returns `content` string with the following first line removed:
 *   )]}'
 */
function stripXsrfTokens(content: string): string {
  return content.replace(new RegExp(`^\\s*\\)]}'\\s*`), '');
}

async function golangRefsApi(): Promise<string> {
  // TODO(jzacsh): implement: switch this to /var/run/user/$UID/ cached file, with TTL O(days)
  //    'https://go.googlesource.com/go/+refs/tags?format=JSON'
  return await readTextFile('/home/jzacsh/tmp/golangrefs-tags.json');
  return `)]}'
{
  "go1": {
    "value": "6174b5e21e73714c63061e66efdbe180e1c5491d"
  },
  "go1.0.1": {
    "value": "2fffba7fe19690e038314d17a117d6b87979c89f"
  },
  "go1.0.2": {
    "value": "cb6c6570b73a1c4d19cad94570ed277f7dae55ac"
  }
}
`;
}

function assert<T>(expectation: T, errorMessage: string): T {
  if (expectation) return expectation;
  throw new Error(`assert: ${errorMessage}`);
}

const comparatorALarger: ComparatorALarger = -1;
const comparatorEqual: ComparatorEqual = 0;
const comparatorBLarger: ComparatorBLarger = 1;

type ComparatorALarger = -1;
type ComparatorEqual = 0;
type ComparatorBLarger = 1;
type ComparatorResult = ComparatorALarger|ComparatorEqual|ComparatorBLarger;

function comparatorString(result: ComparatorResult): string {
  switch(result) {
    case comparatorALarger:
      return 'A larger';
    case comparatorEqual:
      return 'equal';
    case comparatorBLarger:
      return 'B larger';
  }
}

function compareNumbers(a: number, b: number): ComparatorResult {
  if (a === b) return comparatorEqual;
  return a < b ? comparatorBLarger : comparatorALarger;
}

function maybeLog(
  logLabel: string,
  a: string,
  b: string,
  result: ComparatorResult,
): ComparatorResult {
  if (DEBUGGING) {
    console.log(`[${logLabel}] comparing a="${a}" vs b="${b}" --> ${
      comparatorString(result)
    }`);
  }
  return result;
}

class SemVerPart {
  private static readonly NumericRegexp = /^(\d+)/;
  public isNumeric: boolean;
  constructor(private readonly part: string) {
    this.isNumeric = !!part.match(SemVerPart.NumericRegexp);
  }
  getNumber(): number {
    const match: string = assert(
      this.part.match(/^(\d+)/),
      `parse error: encountered semver identity "${this.part}" with no numeric component`,
    )![1];
    return Number.parseInt(match, 10 /*radix*/);
  }

  toString(): string {
    return `${this.part}[num=${this.getNumber()}]`
  }

  compare(b: SemVerPart): ComparatorResult {
    return maybeLog(
        "SemVerPart",  // logLabel
        this.toString(),
        b.toString(),
        SemVerPart.comparator(this  /*a*/, b));
  }
  static comparator(a: SemVerPart, b: SemVerPart): ComparatorResult {
    const aNum = a.getNumber();
    const bNum = b.getNumber();
    const naiveResult = compareNumbers(aNum, bNum);
    if (a.isNumeric && b.isNumeric) return naiveResult;

    if (naiveResult !== comparatorEqual) return naiveResult;
    return b.isNumeric ? comparatorBLarger : comparatorALarger;
  }
}

class SemVer {
  public readonly parse: Array<SemVerPart>;
  private static readonly SEM_VER_DELIM: string = '.';
  constructor(private readonly raw: string) {
    assert(raw.trim().length, `parsing an empty string: "${raw}"`);
    const parts: Array<string> = raw.split(SemVer.SEM_VER_DELIM);
    parts.forEach(p => assert(p.trim(), `found empty identifier "${p}"`));
    assert(parts.length, `zero parts found on version tag: "${raw}"`);
    this.parse = parts.map(p => new SemVerPart(p));
  }

  toString(): string {
    return this.raw;
  }

  compare(b: SemVer): ComparatorResult {
    return maybeLog(
        "SemVer",  // logLabel
        this.toString(),
        b.toString(),
        SemVer.comparator(this  /*a*/, b));
  }

  static comparator(a: SemVer, b: SemVer): ComparatorResult {
    for (let i = 0; i < Math.min(a.parse.length, b.parse.length); i++) {
      if (i > a.parse.length - 1 || i > b.parse.length - 1) break; // impossible

      let idResult = a.parse[i].compare(b.parse[i]);
      if (idResult === comparatorEqual) continue;
      return idResult;
    }
    if (a.parse.length === b.parse.length) comparatorEqual;
    return a.parse.length < b.parse.length ? comparatorBLarger : comparatorALarger;
  }
}

/**
 * Super crude semver utility. Does not support 90% of the grammar of
 * any semver.org specifications.
 *
 * NOTE: golang does NOT adhere semver.org spec anyway.
 */
class SemVerReader {
  private readonly slugRegexp: RegExp;
  constructor(
    private readonly slug: string = '',
  ) {
    this.slugRegexp = new RegExp(`^${this.slug}`);
  }

  isTag(tag: string): boolean {
    if (!this.slug)
      throw new Error(`unimplemented: SemVer doesn't parse tags to check for semver.org validity`);

    return !!tag.match(this.slugRegexp);
  }

  private tagToSemver(tag: string): SemVer {
    return new SemVer(tag.replace(this.slugRegexp, ''));
  }

  comparator(aTag: string, bTag: string): ComparatorResult {
    const a = this.tagToSemver(aTag);
    const b = this.tagToSemver(bTag);
    const result = a.compare(b);
    return maybeLog(
        "SemVerReader"  /*logLabel*/,
        a.toString(),
        b.toString(),
        result);
  }
}

async function golangTags(): Promise<Array<string>> {
  const resp = await stripXsrfTokens(await golangRefsApi());

  const semVerReader = new SemVerReader('go');
  return Object.
    keys(JSON.parse(resp)).

    // Do some simple hygiene of inputs
    map(tag => tag.trim()).
    filter(tag => tag).

    // Interpret semver values as presented as git tags
    filter(tag => semVerReader.isTag(tag)).
    sort((a, b) => semVerReader.comparator(a, b));
}

async function golangRefsJson(): Promise<Array<string>> {
  const tags = await golangTags();
  return [tags[0], tags[tags.length - 1]];
}

// TODO(jzacsh): implement: actually compare to `go version` output and do
// nothing if identical.
console.log('newest tag: "%s"', await golangRefsJson());
