-- ==============================================================================
-- CropGuard AI: Master Database Migration 001 - Initial Schema & Seed Data
-- Target Database: Supabase PostgreSQL
-- Features:
--   1. Extensions (UUID-OSSP / PGCrypto)
--   2. Profiles Table (Linked to auth.users with auto-creation trigger)
--   3. Pest Categories Table (With scientific details, crop associations & bilingual Telugu support)
--   4. Uploaded Images Table (Storage references and crop classification)
--   5. Predictions Table (Model versioning, latency, detection summary)
--   6. Detection Items Table (Bounding box normalized coordinates & confidence)
--   7. Row-Level Security (RLS) Policies ensuring strict tenant data isolation
--   8. Seed Data for 6 Harmful Crop Pests (English & Telugu)
--   9. Supabase Storage Bucket setup for 'cropguard-images'
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    preferred_language VARCHAR(5) DEFAULT 'en' CHECK (preferred_language IN ('en', 'te')),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Index for profile queries
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Automatic profile creation on auth.users sign-up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, preferred_language)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'preferred_language', 'en')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 3. PEST CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.pest_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pest_name TEXT NOT NULL UNIQUE,
    scientific_name TEXT NOT NULL,
    affected_crops TEXT[] NOT NULL DEFAULT '{}',
    description TEXT NOT NULL,
    description_te TEXT,
    symptoms TEXT NOT NULL,
    symptoms_te TEXT,
    preventive_guidance TEXT NOT NULL,
    preventive_guidance_te TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_pest_categories_name ON public.pest_categories(pest_name);


-- 4. UPLOADED IMAGES TABLE
CREATE TABLE IF NOT EXISTS public.uploaded_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    crop_type VARCHAR(50) NOT NULL DEFAULT 'Other',
    file_size_bytes BIGINT,
    mime_type VARCHAR(50) DEFAULT 'image/jpeg',
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_uploaded_images_user ON public.uploaded_images(user_id);
CREATE INDEX IF NOT EXISTS idx_uploaded_images_crop ON public.uploaded_images(crop_type);


-- 5. PREDICTIONS TABLE
CREATE TABLE IF NOT EXISTS public.predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    uploaded_image_id UUID NOT NULL REFERENCES public.uploaded_images(id) ON DELETE CASCADE,
    annotated_image_path TEXT,
    model_version VARCHAR(50) NOT NULL DEFAULT 'yolo11s-v1.0',
    detection_status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (detection_status IN ('detected', 'no_pest_detected', 'failed', 'pending')),
    total_detections INTEGER NOT NULL DEFAULT 0,
    processing_time_sec NUMERIC(6, 3),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_predictions_user ON public.predictions(user_id);
CREATE INDEX IF NOT EXISTS idx_predictions_image ON public.predictions(uploaded_image_id);
CREATE INDEX IF NOT EXISTS idx_predictions_created ON public.predictions(created_at DESC);


-- 6. DETECTION ITEMS TABLE
CREATE TABLE IF NOT EXISTS public.detection_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_id UUID NOT NULL REFERENCES public.predictions(id) ON DELETE CASCADE,
    pest_category_id UUID REFERENCES public.pest_categories(id) ON DELETE SET NULL,
    confidence NUMERIC(5, 4) NOT NULL CHECK (confidence >= 0.0 AND confidence <= 1.0),
    x_min NUMERIC(7, 4) NOT NULL,
    y_min NUMERIC(7, 4) NOT NULL,
    x_max NUMERIC(7, 4) NOT NULL,
    y_max NUMERIC(7, 4) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_detection_items_prediction ON public.detection_items(prediction_id);
CREATE INDEX IF NOT EXISTS idx_detection_items_pest ON public.detection_items(pest_category_id);


-- 7. ROW-LEVEL SECURITY (RLS) POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pest_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.uploaded_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.detection_items ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view & update only their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Pest Categories: Readable by all authenticated or anonymous users
CREATE POLICY "Anyone can view pest categories"
    ON public.pest_categories FOR SELECT
    USING (true);

-- Uploaded Images: Strict isolation per user
CREATE POLICY "Users can view own uploaded images"
    ON public.uploaded_images FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own uploaded images"
    ON public.uploaded_images FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own uploaded images"
    ON public.uploaded_images FOR DELETE
    USING (auth.uid() = user_id);

-- Predictions: Strict isolation per user
CREATE POLICY "Users can view own predictions"
    ON public.predictions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own predictions"
    ON public.predictions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own predictions"
    ON public.predictions FOR DELETE
    USING (auth.uid() = user_id);

-- Detection Items: Accessible if the user owns the parent prediction
CREATE POLICY "Users can view detection items of own predictions"
    ON public.detection_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.predictions p
            WHERE p.id = detection_items.prediction_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert detection items for own predictions"
    ON public.detection_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.predictions p
            WHERE p.id = detection_items.prediction_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete detection items for own predictions"
    ON public.detection_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.predictions p
            WHERE p.id = detection_items.prediction_id
            AND p.user_id = auth.uid()
        )
    );


-- 8. SEED DATA: 6 TARGET AGRICULTURAL PESTS (ENGLISH & TELUGU)
INSERT INTO public.pest_categories (pest_name, scientific_name, affected_crops, description, description_te, symptoms, symptoms_te, preventive_guidance, preventive_guidance_te)
VALUES
(
    'Aphids',
    'Aphis gossypii',
    ARRAY['Cotton', 'Chilli', 'Tomato'],
    'Small, soft-bodied sap-sucking insects that multiply rapidly on underside of leaves and tender shoots, secreting sticky honeydew.',
    'ఆకు అడుగు భాగంలో మరియు లేత కొమ్మలపై రసం పీల్చే చిన్న పురుగులు. ఇవి తీపి జిగురు పదార్థాన్ని (హనీడ్యూ) విసర్జిస్తాయి.',
    'Curled, yellowed leaves, stunted crop growth, sooty black mold on leaves, and reduced flowering.',
    'ఆకులు ముడుచుకుపోవడం, పసుపు రంగులోకి మారడం, మొక్క ఎదుగుదల తగ్గడం మరియు ఆకులపై నల్లటి మసి తెగులు ఏర్పడటం.',
    'Conserve natural predators like ladybird beetles. Install yellow sticky traps (15-20 per acre). Spray neem oil (5ml/liter) at early infestation. Avoid excessive chemical nitrogen fertilizers.',
    'లేడీబర్డ్ బీటిల్స్ వంటి సహజ మిత్రపురుగులను రక్షించండి. ఎకరాకు 15-20 పసుపు రంగు జిగురు అట్టలను ఏర్పాటు చేయండి. ఆరంభ దశలో వేప నూనె (5 మి.లీ / లీటరు నీటికి) పిచికారీ చేయండి. అధిక యూరియా వినియోగాన్ని నివారించండి.'
),
(
    'Whitefly',
    'Bemisia tabaci',
    ARRAY['Cotton', 'Tomato', 'Chilli'],
    'Tiny, moth-like white flying insects that suck sap from the undersides of leaves and transmit viral diseases such as leaf curl virus.',
    'ఆకుల అడుగున చేరి రసం పీల్చే తెల్లటి చిన్న పురుగులు. ఇవి ఆకు ముడత వంటి తీవ్రమైన వైరస్ తెగుళ్లను వ్యాప్తి చేస్తాయి.',
    'Chlorotic yellow spots on leaves, premature leaf drop, leaf curling, sticky leaves with black mold, and vector transmission of Gemini viruses.',
    'ఆకులపై పసుపు మచ్చలు, ఆకులు రాలిపోవడం, పైకి ముడుచుకోవడం మరియు నల్లటి మసి తెగులు పెరగడం.',
    'Install yellow sticky traps at canopy level. Maintain clean weed-free borders. Spray 5% neem seed kernel extract (NSKE) or mineral oil sprays. Avoid synthetic pyrethroid overuse which flares up whitefly populations.',
    'పంట పైభాగంలో పసుపు రంగు జిగురు అట్టలను అమర్చండి. గట్లపై కలుపు మొక్కలను నివారించండి. 5% వేప గింజల కషాయం (NSKE) పిచికారీ చేయండి. విచక్షణారహిత సింథటిక్ పురుగుమందుల వాడకాన్ని నివారించండి.'
),
(
    'Brown Planthopper',
    'Nilaparvata lugens',
    ARRAY['Paddy/Rice'],
    'A major destructive pest of rice that feeds at the base of rice tillers, causing hopper burn where plants dry up in circular patches.',
    'వరి పైరును తీవ్రంగా ఆశించే రసం పీల్చే పురుగు. ఇది దుబ్బుల కింద కాండం వద్ద చేరి రసం పీల్చి పైరును ఎండుపొట్ట (హాప్పర్ బర్న్) బారిన పడేస్తుంది.',
    'Yellowing of leaves starting from base, drying of tillers, circular patches of dry brown plants appearing as if burnt (hopper burn).',
    'మొదట ఆకులు పసుపుబారి, తరువాత దుబ్బులు ఎండిపోయి పొలంలో గుండ్రటి మచ్చల రూపంలో పైరు కాలిపోయినట్లు ఎండిపోతుంది.',
    'Practice alternate wetting and drying (AWD) irrigation; avoid continuous stagnant water. Maintain 30 cm alleyways every 2-3 meters in transplanted paddy. Avoid excessive nitrogen fertilizer. Protect spiders and mirid bugs.',
    'పొలంలో నీరు నిల్వ ఉండకుండా ఆరుతడులు ఇవ్వండి. ప్రతి 2-3 మీటర్లకు ఒకసారి 30 సెం.మీ కాలిబాటలు ఏర్పాటు చేయండి. అధిక మోతాదులో యూరియా వాడకండి. సాలీళ్ళు మరియు మిరిడ్ బగ్స్ వంటి మిత్రపురుగులను సంరక్షించండి.'
),
(
    'Yellow Stem Borer',
    'Scirpophaga incertulas',
    ARRAY['Paddy/Rice'],
    'Caterpillars bore into rice stems during vegetative and reproductive stages, causing dead hearts and white ears.',
    'వరిలో మొవ్వు మరియు వెన్ను దశల్లో కాండంలోకి తొలిచి తీవ్ర నష్టం కలిగించే ప్రధాన పురుగు.',
    'Dead central shoot (dead heart) during vegetative stage that easily pulls out; bleached empty white panicles (white ear) during heading stage.',
    'పైరు పెరిగే దశలో మొవ్వు చనిపోవడం (మొవ్వు కుళ్ళు) మరియు ఈనిన దశలో తెల్ల కంకులు (తాలు వెన్నులు) ఏర్పడటం.',
    'Clip seedling tips before transplanting to eliminate egg masses. Set up pheromone traps (5-8 per acre) for monitoring. Release egg parasitoids (Trichogramma japonicum) at 40,000/acre at weekly intervals.',
    'నాట్లు వేసే ముందు నారు కొనలను తుంచడం ద్వారా గుడ్ల సముదాయాలను తొలగించండి. ఎకరాకు 5-8 లింగాకర్షక బుట్టలను అమర్చండి. ట్రైకోగ్రామా పరాన్నజీవులను విడుదల చేయండి.'
),
(
    'Thrips',
    'Scirtothrips dorsalis',
    ARRAY['Chilli', 'Cotton', 'Tomato'],
    'Slender, minute insects with fringed wings that scrape the leaf surface and suck exuding plant cell sap, leading to upward leaf curling.',
    'ఆకులను గీకి వచ్చే రసాన్ని పీల్చే అతి సూక్ష్మమైన పురుగులు. వీటి ఉధృతి వల్ల ఆకులు పైకి దోనెలాగా ముడుచుకుంటాయి.',
    'Upward curling and crinkling of leaves (boat-shaped leaf symptom), bronzing of lower leaf surface, flower drop, and scarred fruit.',
    'ఆకులు పైకి దోనెలా ముడుచుకుపోవడం, ఆకుల అడుగుభాగం రాగి రంగులోకి మారడం, పూత రాలిపోవడం మరియు కాయలపై గీతలు ఏర్పడటం.',
    'Install blue sticky traps (15-20 per acre) which specifically attract thrips. Grow barrier crops like maize or sorghum around chilli fields. Spray pongamia or neem oil (5ml/L) early. Ensure balanced potash fertilization.',
    'ఎకరాకు 15-20 నీలం రంగు జిగురు అట్టలను ఏర్పాటు చేయండి. పొలం చుట్టూ మొక్కజొన్న లేదా జొన్నను రక్షణ పంటగా వేయండి. వేప లేదా కానుగ నూనె పిచికారీ చేయండి.'
),
(
    'Helicoverpa armigera',
    'Helicoverpa armigera',
    ARRAY['Tomato', 'Cotton', 'Chilli'],
    'Voracious polyphagous caterpillar commonly known as American bollworm or fruit borer that bores into developing buds, bolls, and fruits.',
    'టమోటా, పత్తి మరియు మిరప కాయలలోకి తొలచి తినే ప్రమాదకరమైన శనగపచ్చ పురుగు (కాయ తొలుచు పురుగు).',
    'Round holes bored into fruits, tomato fruits with rotting and larval excreta, fallen flowers and squares, hollowed cotton bolls.',
    'కాయలపై గుండ్రటి రంధ్రాలు ఏర్పడటం, కాయలు కుళ్ళిపోవడం, పురుగు విసర్జన కాయల రంధ్రాల వద్ద కనిపించడం, పూత రాలిపోవడం.',
    'Install pheromone traps (5 per acre) for adult moth monitoring. Plant African marigold as a trap crop around tomato (1:16 ratio). Handpick and destroy large larvae in small holdings. Spray HaNPV (Helicoverpa Nuclear Polyhedrosis Virus) @ 250 LE/acre with jaggery in evening hours.',
    'ఎకరాకు 5 లింగాకర్షక బుట్టలను అమర్చండి. టమోటా చుట్టూ బంతి పూల మొక్కలను ఎర పంటగా సాగు చేయండి. పెద్ద గొంగళి పురుగులను ఏరి నాశనం చేయండి. సాయంత్రం వేళల్లో HaNPV ద్రావణాన్ని బెల్లంతో కలిపి పిచికారీ చేయండి.'
)
ON CONFLICT (pest_name) DO UPDATE SET
    scientific_name = EXCLUDED.scientific_name,
    affected_crops = EXCLUDED.affected_crops,
    description = EXCLUDED.description,
    description_te = EXCLUDED.description_te,
    symptoms = EXCLUDED.symptoms,
    symptoms_te = EXCLUDED.symptoms_te,
    preventive_guidance = EXCLUDED.preventive_guidance,
    preventive_guidance_te = EXCLUDED.preventive_guidance_te;


-- 9. STORAGE BUCKET CONFIGURATION (Supabase Storage)
INSERT INTO storage.buckets (id, name, public)
VALUES ('cropguard-images', 'cropguard-images', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Public read access for images, authenticated upload/delete
CREATE POLICY "Public image access"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'cropguard-images');

CREATE POLICY "Authenticated users can upload images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'cropguard-images'
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Users can update/delete own images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'cropguard-images'
        AND auth.uid() = owner
    );
