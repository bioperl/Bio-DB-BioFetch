# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use Bio::Root::Test;

    test_begin(-tests               => 36,
               -requires_modules    => [qw(IO::String
                                           LWP::UserAgent)],
               -requires_networking => 1);

    use_ok('Bio::DB::BioFetch');
}

my $verbose = test_debug();

my ($db,$db2,$seq,$seqio);

{
    # get a single seq
    ok defined($db = Bio::DB::BioFetch->new(-verbose => $verbose));
    # get a RefSeq entry
    ok $db->db('refseqn');
    $seq = $db->get_Seq_by_acc('NM_006732'); # RefSeq VERSION
    isa_ok($seq, 'Bio::SeqI');
    is($seq->accession_number,'NM_006732');
    is($seq->accession_number,'NM_006732');
    is( $seq->length, 3776);
}

{
    # EMBL
    $db->db('embl');
    $seq = $db->get_Seq_by_acc('J02231');
    isa_ok($seq, 'Bio::SeqI');
    is($seq->id, 'J02231');
    is($seq->length, 200);
}

{
    $seqio = $db->get_Stream_by_id(['AEE33958']);
    undef $db; # testing to see if we can remove gb
    $seq = $seqio->next_seq();
    isa_ok($seqio, 'Bio::SeqIO');
    isa_ok($seq, 'Bio::SeqI');
    cmp_ok( $seq->length, '>=', 1);
}

SKIP: {
    #swissprot
    ok $db2 = Bio::DB::BioFetch->new(-db => 'swissprot');
    test_skip(-tests => 5, -requires_module => 'Data::Stag');
    $seq = $db2->get_Seq_by_id('YNB3_YEAST');
    isa_ok($seq, 'Bio::SeqI');
    is($seq->length, 125);
    is($seq->division, 'YEAST');
    $db2->request_format('fasta');
    $seq = $db2->get_Seq_by_acc('P43780');
    isa_ok($seq, 'Bio::SeqI');
    is($seq->length,103);
}

$seq = $seqio = undef;

{
    ok $db = Bio::DB::BioFetch->new(-retrievaltype => 'tempfile',
                                    -format        => 'fasta',
                                    -verbose       => $verbose
                                    );
    $db->db('embl');
    $seqio = $db->get_Stream_by_id('J00522 AF303112 J02231');
    my %seqs;
    # don't assume anything about the order of the sequences
    while ( my $s = $seqio->next_seq ) {
        isa_ok($s, 'Bio::SeqI');
        my ($type,$x,$name) = split(/\|/,$s->display_id);
        $seqs{$x} = $s->length;
    }
    isa_ok($seqio, 'Bio::SeqIO');
    is($seqs{'J00522'},408);
    is($seqs{'AF303112'},1611);
    is($seqs{'J02231'},200);
}

{
    ok $db = Bio::DB::BioFetch->new(-db      => 'embl',
                                    -verbose => $verbose ? $verbose : -1);

    # check contig warning (WebDBSeqI)
    eval {
        $seq = $db->get_Seq_by_acc('NT_006732');
    };
    like($@, qr{contigs are whole chromosome files}, 'contig warning');
    $seq = $db->get_Seq_by_acc('NM_006732');
    isa_ok($seq, 'Bio::SeqI');
    is($seq->length,3776);
}

# unisave
{
    ok $db = Bio::DB::BioFetch->new(-db      => 'unisave',
                                    -verbose => $verbose ? $verbose : -1);
    $seq = $db->get_Seq_by_acc('P14733');
    isa_ok($seq, 'Bio::SeqI');
    is($seq->display_id, 'LMNB1_MOUSE');
    is($seq->accession, 'P14733');
    is($seq->length, 588);
}
