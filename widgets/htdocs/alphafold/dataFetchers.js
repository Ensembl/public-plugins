import { getHexColor } from "./colorHelpers.js";

const commonOptions = {
  headers: {
    'Content-Type': 'application/json'
  },
};

/**
 * @param {Object} params - Function parameters.
 * @param {string} params.rootUrl - Root url of the api.
 * @param {string} params.enspId - Ensembl identifier of the protein molecule.
*/
export const fetchAlphaFoldId = async (params) => {
  const { rootUrl: apiRoot, enspId } = params;
  const url = `${apiRoot}/overlap/translation/${enspId}?feature=protein_feature;type=alphafold`;
  const alphafoldFeatures = await fetch(url, commonOptions)
    .then(response => response.json()); // should be an array of one feature
  const { id: alphaFoldId } = alphafoldFeatures[0];

  // Note that the alphafold id will end in the name of the chain (e.g. "AF-Q9S745-F1.A").
  // The chain has to be discarded when passed to Molstar
  return alphaFoldId.split('.').shift();
};

/**
 * @param {Object} params - Function parameters.
 * @param {string} params.rootUrl - Root url of the api.
 * @param {string} params.enspId - Ensembl identifier of the protein molecule.
 */
export const fetchExons = async (params) => {
  const { rootUrl: apiRoot, enspId } = params;
  const url = `${apiRoot}/overlap/translation/${enspId}?feature=translation_exon`;
  const exons = await fetch(url, commonOptions)
    .then(response => response.json());
  exons.sort((exonA, exonB) => exonA.rank - exonB.rank);
  // last exon's end position includes a stop codon; exclude it
  exons[exons.length - 1].end -= 1;

  return exons.map((exon, index) => ({
    ...exon,
    color: getHexColor(index, index + 1)
  }));
};

/**
 * @param {Object} params - Function parameters.
 * @param {string} params.rootUrl - Root url of the api.
 * @param {string} params.enspId - Ensembl identifier of the protein molecule.
 */
export const fetchVariants = async (params) => {
  const { rootUrl: apiRoot, enspId } = params;
  const url = `${apiRoot}/overlap/translation/${enspId}?feature=transcript_variation`;
  const variants = await fetch(url, commonOptions)
    .then(response => response.json());
  const siftVariants = variants.filter(variant => variant.sift);
  const polyphenVariants = variants.filter(variant => variant.polyphen);

  return {
    sift: processSifts(siftVariants),
    polyphen: processPolyphens(polyphenVariants)
  };
};

const processSifts = (siftVariants) => {
  // Sort:
  //   - by start position (starting closer to the beginning of the protein go first)
  //   - in case of tie, by sift score reflecting the severity of the variant (lower score means worse tolerated)
  siftVariants.sort((a, b) => {
    return a.start - b.start || b.sift - a.sift;
  });

  return siftVariants.map(variant => {
    const siftScore = parseFloat(variant.sift);

    return {
      ...variant,
      sift_class: siftScore <= 0.05 ? 'score_bad' : 'score_good',
      color: siftScore <= 0.05 ? 'red' : 'green'
    };
  });
};

const processPolyphens = (polyphenVariants) => {
  // Sort:
  //   - by start position (starting closer to the beginning of the protein go first)
  //   - in case of tie, by polyphen score reflecting the severity of the variant (higher score means worse tolerated)
  polyphenVariants.sort((a, b) => {
    return a.start - b.start || a.polyphen - b.polyphen;
  });

  return polyphenVariants.map(variant => {
    const polyphenScore = parseFloat(variant.polyphen);
    let polyphenClass, polyphenColor;
    if (polyphenScore > 0.908) {
      polyphenClass = 'score_bad',
      polyphenColor = 'red';
    } else if (polyphenScore > 0.445 && polyphenScore <= 0.908) {
      polyphenClass = 'score_doubtful',
      polyphenColor = 'orange';
    } else {
      polyphenClass = 'score_good',
      polyphenColor = 'green';
    }

    return {
      ...variant,
      polyphen_class: polyphenClass,
      color: polyphenColor,
    }
  });
}
