import logging
from typing import Dict, List, Optional
from app.database.supabase_client import supabase_client
from app.schemas.pest import PestCategoryResponse

logger = logging.getLogger("cropguard.pests")

# Comprehensive offline agricultural knowledge base for the 6 target pests
# (English & Telugu) ensuring reliable operation even before Supabase SQL migration is run.
SEED_PEST_KNOWLEDGE: List[Dict] = [
    {
        "id": "pest-aphids-001",
        "pest_name": "Aphids",
        "scientific_name": "Aphis gossypii",
        "affected_crops": ["Cotton", "Chilli", "Tomato"],
        "description": "Small, soft-bodied sap-sucking insects that multiply rapidly on underside of leaves and tender shoots, secreting sticky honeydew.",
        "description_te": "ఆకు అడుగు భాగంలో మరియు లేత కొమ్మలపై రసం పీల్చే చిన్న పురుగులు. ఇవి తీపి జిగురు పదార్థాన్ని (హనీడ్యూ) విసర్జిస్తాయి.",
        "symptoms": "Curled, yellowed leaves, stunted crop growth, sooty black mold on leaves, and reduced flowering.",
        "symptoms_te": "ఆకులు ముడుచుకుపోవడం, పసుపు రంగులోకి మారడం, మొక్క ఎదుగుదల తగ్గడం మరియు ఆకులపై నల్లటి మసి తెగులు ఏర్పడటం.",
        "preventive_guidance": "Conserve natural predators like ladybird beetles. Install yellow sticky traps (15-20 per acre). Spray neem oil (5ml/liter) at early infestation. Avoid excessive chemical nitrogen fertilizers.",
        "preventive_guidance_te": "లేడీబర్డ్ బీటిల్స్ వంటి సహజ మిత్రపురుగులను రక్షించండి. ఎకరాకు 15-20 పసుపు రంగు జిగురు అట్టలను ఏర్పాటు చేయండి. ఆరంభ దశలో వేప నూనె (5 మి.లీ / లీటరు నీటికి) పిచికారీ చేయండి. అధిక యూరియా వినియోగాన్ని నివారించండి."
    },
    {
        "id": "pest-whitefly-002",
        "pest_name": "Whitefly",
        "scientific_name": "Bemisia tabaci",
        "affected_crops": ["Cotton", "Tomato", "Chilli"],
        "description": "Tiny, moth-like white flying insects that suck sap from the undersides of leaves and transmit viral diseases such as leaf curl virus.",
        "description_te": "ఆకుల అడుగున చేరి రసం పీల్చే తెల్లటి చిన్న పురుగులు. ఇవి ఆకు ముడత వంటి తీవ్రమైన వైరస్ తెగుళ్లను వ్యాప్తి చేస్తాయి.",
        "symptoms": "Chlorotic yellow spots on leaves, premature leaf drop, leaf curling, sticky leaves with black mold, and vector transmission of Gemini viruses.",
        "symptoms_te": "ఆకులపై పసుపు మచ్చలు, ఆకులు రాలిపోవడం, పైకి ముడుచుకోవడం మరియు నల్లటి మసి తెగులు పెరగడం.",
        "preventive_guidance": "Install yellow sticky traps at canopy level. Maintain clean weed-free borders. Spray 5% neem seed kernel extract (NSKE) or mineral oil sprays. Avoid synthetic pyrethroid overuse which flares up whitefly populations.",
        "preventive_guidance_te": "పంట పైభాగంలో పసుపు రంగు జిగురు అట్టలను అమర్చండి. గట్లపై కలుపు మొక్కలను నివారించండి. 5% వేప గింజల కషాయం (NSKE) పిచికారీ చేయండి. విచక్షణారహిత సింథటిక్ పురుగుమందుల వాడకాన్ని నివారించండి."
    },
    {
        "id": "pest-bph-003",
        "pest_name": "Brown Planthopper",
        "scientific_name": "Nilaparvata lugens",
        "affected_crops": ["Paddy/Rice"],
        "description": "A major destructive pest of rice that feeds at the base of rice tillers, causing hopper burn where plants dry up in circular patches.",
        "description_te": "వరి పైరును తీవ్రంగా ఆశించే రసం పీల్చే పురుగు. ఇది దుబ్బుల కింద కాండం వద్ద చేరి రసం పీల్చి పైరును ఎండుపొట్ట (హాప్పర్ బర్న్) బారిన పడేస్తుంది.",
        "symptoms": "Yellowing of leaves starting from base, drying of tillers, circular patches of dry brown plants appearing as if burnt (hopper burn).",
        "symptoms_te": "మొదట ఆకులు పసుపుబారి, తరువాత దుబ్బులు ఎండిపోయి పొలంలో గుండ్రటి మచ్చల రూపంలో పైరు కాలిపోయినట్లు ఎండిపోతుంది.",
        "preventive_guidance": "Practice alternate wetting and drying (AWD) irrigation; avoid continuous stagnant water. Maintain 30 cm alleyways every 2-3 meters in transplanted paddy. Avoid excessive nitrogen fertilizer. Protect spiders and mirid bugs.",
        "preventive_guidance_te": "పొలంలో నీరు నిల్వ ఉండకుండా ఆరుతడులు ఇవ్వండి. ప్రతి 2-3 మీటర్లకు ఒకసారి 30 సెం.మీ కాలిబాటలు ఏర్పాటు చేయండి. అధిక మోతాదులో యూరియా వాడకండి. సాలీళ్ళు మరియు మిరిడ్ బగ్స్ వంటి మిత్రపురుగులను సంరక్షించండి."
    },
    {
        "id": "pest-ysb-004",
        "pest_name": "Yellow Stem Borer",
        "scientific_name": "Scirpophaga incertulas",
        "affected_crops": ["Paddy/Rice"],
        "description": "Caterpillars bore into rice stems during vegetative and reproductive stages, causing dead hearts and white ears.",
        "description_te": "వరిలో మొవ్వు మరియు వెన్ను దశల్లో కాండంలోకి తొలిచి తీవ్ర నష్టం కలిగించే ప్రధాన పురుగు.",
        "symptoms": "Dead central shoot (dead heart) during vegetative stage that easily pulls out; bleached empty white panicles (white ear) during heading stage.",
        "symptoms_te": "పైరు పెరిగే దశలో మొవ్వు చనిపోవడం (మొవ్వు కుళ్ళు) మరియు ఈనిన దశలో తెల్ల కంకులు (తాలు వెన్నులు) ఏర్పడటం.",
        "preventive_guidance": "Clip seedling tips before transplanting to eliminate egg masses. Set up pheromone traps (5-8 per acre) for monitoring. Release egg parasitoids (Trichogramma japonicum) at 40,000/acre at weekly intervals.",
        "preventive_guidance_te": "నాట్లు వేసే ముందు నారు కొనలను తుంచడం ద్వారా గుడ్ల సముదాయాలను తొలగించండి. ఎకరాకు 5-8 లింగాకర్షక బుట్టలను అమర్చండి. ట్రైకోగ్రామా పరాన్నజీవులను విడుదల చేయండి."
    },
    {
        "id": "pest-thrips-005",
        "pest_name": "Thrips",
        "scientific_name": "Scirtothrips dorsalis",
        "affected_crops": ["Chilli", "Cotton", "Tomato"],
        "description": "Slender, minute insects with fringed wings that scrape the leaf surface and suck exuding plant cell sap, leading to upward leaf curling.",
        "description_te": "ఆకులను గీకి వచ్చే రసాన్ని పీల్చే అతి సూక్ష్మమైన పురుగులు. వీటి ఉధృతి వల్ల ఆకులు పైకి దోనెలాగా ముడుచుకుంటాయి.",
        "symptoms": "Upward curling and crinkling of leaves (boat-shaped leaf symptom), bronzing of lower leaf surface, flower drop, and scarred fruit.",
        "symptoms_te": "ఆకులు పైకి దోనెలా ముడుచుకుపోవడం, ఆకుల అడుగుభాగం రాగి రంగులోకి మారడం, పూత రాలిపోవడం మరియు కాయలపై గీతలు ఏర్పడటం.",
        "preventive_guidance": "Install blue sticky traps (15-20 per acre) which specifically attract thrips. Grow barrier crops like maize or sorghum around chilli fields. Spray pongamia or neem oil (5ml/L) early. Ensure balanced potash fertilization.",
        "preventive_guidance_te": "ఎకరాకు 15-20 నీలం రంగు జిగురు అట్టలను ఏర్పాటు చేయండి. పొలం చుట్టూ మొక్కజొన్న లేదా జొన్నను రక్షణ పంటగా వేయండి. వేప లేదా కానుగ నూనె పిచికారీ చేయండి."
    },
    {
        "id": "pest-bollworm-006",
        "pest_name": "Helicoverpa armigera",
        "scientific_name": "Helicoverpa armigera",
        "affected_crops": ["Tomato", "Cotton", "Chilli"],
        "description": "Voracious polyphagous caterpillar commonly known as American bollworm or fruit borer that bores into developing buds, bolls, and fruits.",
        "description_te": "టమోటా, పత్తి మరియు మిరప కాయలలోకి తొలచి తినే ప్రమాదకరమైన శనగపచ్చ పురుగు (కాయ తొలుచు పురుగు).",
        "symptoms": "Round holes bored into fruits, tomato fruits with rotting and larval excreta, fallen flowers and squares, hollowed cotton bolls.",
        "symptoms_te": "కాయలపై గుండ్రటి రంధ్రాలు ఏర్పడటం, కాయలు కుళ్ళిపోవడం, పురుగు విసర్జన కాయల రంధ్రాల వద్ద కనిపించడం, పూత రాలిపోవడం.",
        "preventive_guidance": "Install pheromone traps (5 per acre) for adult moth monitoring. Plant African marigold as a trap crop around tomato (1:16 ratio). Handpick and destroy large larvae in small holdings. Spray HaNPV @ 250 LE/acre with jaggery in evening hours.",
        "preventive_guidance_te": "ఎకరాకు 5 లింగాకర్షక బుట్టలను అమర్చండి. టమోటా చుట్టూ బంతి పూల మొక్కలను ఎర పంటగా సాగు చేయండి. పెద్ద గొంగళి పురుగులను ఏరి నాశనం చేయండి. సాయంత్రం వేళల్లో HaNPV ద్రావణాన్ని బెల్లంతో కలిపి పిచికారీ చేయండి."
    }
]


class PestService:
    """Service to query agricultural pest identification and preventive advisory."""
    _cached_pests: Optional[List[PestCategoryResponse]] = None

    @classmethod
    def get_all_pests(cls) -> List[PestCategoryResponse]:
        """Fetch all pest categories, cached in-memory to prevent inference latency."""
        if cls._cached_pests is not None:
            return cls._cached_pests

        try:
            records = supabase_client.get("pest_categories")
            if records and len(records) > 0:
                cls._cached_pests = [PestCategoryResponse(**r) for r in records]
                return cls._cached_pests
        except Exception as e:
            logger.debug(f"Querying Supabase pest_categories failed ({e}), using verified local seed data.")

        cls._cached_pests = [PestCategoryResponse(**p) for p in SEED_PEST_KNOWLEDGE]
        return cls._cached_pests

    @staticmethod
    def get_pest_by_id(pest_id: str) -> Optional[PestCategoryResponse]:
        """Find pest by ID or class name."""
        all_pests = PestService.get_all_pests()
        for p in all_pests:
            if p.id == pest_id or p.pest_name.lower() == pest_id.lower():
                return p
        return None

    @staticmethod
    def find_pest_by_name(pest_name: str) -> Optional[PestCategoryResponse]:
        """Look up detailed guidance by detected class name."""
        all_pests = PestService.get_all_pests()
        name_clean = pest_name.strip().lower()
        for p in all_pests:
            if p.pest_name.lower() in name_clean or name_clean in p.pest_name.lower():
                return p
        return None


pest_service = PestService()
