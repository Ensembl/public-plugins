/*
 * Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 * Copyright [2016-2024] EMBL-European Bioinformatics Institute
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

Genoverse.Track.TranslatedSequence = Genoverse.Track.Sequence.extend({
  codonTableId : 1,
  codons       : {},
  
  /*
    Numerical ids based on BioPerl codon table ids.
    The amino acid codes are IUPAC recommendations for common amino acids:
      A      Ala      Alanine
      R      Arg      Arginine
      N      Asn      Asparagine
      D      Asp      Aspartic acid
      C      Cys      Cysteine
      Q      Gln      Glutamine
      E      Glu      Glutamic acid
      G      Gly      Glycine
      H      His      Histidine
      I      Ile      Isoleucine
      L      Leu      Leucine
      K      Lys      Lysine
      M      Met      Methionine
      F      Phe      Phenylalanine
      P      Pro      Proline
      O      Pyl      Pyrrolysine (22nd amino acid)
      U      Sec      Selenocysteine (21st amino acid)
      S      Ser      Serine
      T      Thr      Threonine
      W      Trp      Tryptophan
      Y      Tyr      Tyrosine
      V      Val      Valine
      B      Asx      Aspartic acid or Asparagine
      Z      Glx      Glutamine or Glutamic acid
      J      Xle      Isoleucine or Valine (mass spec ambiguity)
      X      Xaa      Any or unknown amino acid
  */
  translate: {
    1  : 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Standard
    2  : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG',  // Vertebrate Mitochondrial
    3  : 'FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Yeast Mitochondrial
    4  : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Mold Protozoan and CoelenterateMitochondrial and Mycoplasma/Spiroplasma
    5  : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG',  // Invertebrate Mitochondrial
    6  : 'FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Ciliate Dasycladacean and Hexamita Nuclear
    9  : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG',  // Echinoderm Mitochondrial
    11 : 'FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Euplotid Nuclear
    10 : 'FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Bacterial
    12 : 'FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Alternative Yeast Nuclear
    13 : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG',  // Ascidian Mitochondrial
    14 : 'FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG',  // Flatworm Mitochondrial
    15 : 'FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Blepharisma Nuclear
    16 : 'FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Chlorophycean Mitochondrial
    21 : 'FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG',  // Trematode Mitochondrial
    22 : 'FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG',  // Scenedesmus obliquus Mitochondrial
    23 : 'FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG'   // Thraustochytrium Mitochondrial
  },
  
  constructor: function () {
    var bases = this.lowerCase ? [ 't', 'c', 'a', 'g' ] : [ 'T', 'C', 'A', 'G' ];
    var x     = 0;
    var j, k;
    
    for (var i in bases) {
      for (j in bases) {
        for (k in bases) {
          this.codons[bases[i] + bases[j] + bases[k]] = x++;
        }
      }
    }
    
    if (this.lowerCase) {
      for (i in this.translate) {
        this.translate[i] = this.translate[i].toLowerCase();
      }
    }
    
    this.base.apply(this, arguments);
  }
});