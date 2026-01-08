\unset ECHO
\pset format unaligned
\pset tuples_only true

create extension if not exists pgtap;

create extension if not exists pgsqlmock;

create schema if not exists tests;

begin;

SELECT plan(1);

create or replace view public.some_view
as
select * from (values(1, 'a'), (2, 'b'), (3, 'c')) as t(id, f);

create or replace function tests.test_view_mocking() RETURNS SETOF TEXT AS $$
BEGIN	
	PREPARE some_view_should_be AS select * from (values(1, 'x'), (2, 'y'), (3, 'z')) as t(id, f) ORDER BY id;
	perform mock_view('public', 'some_view',
		_return_set_sql => 'select * from (values(1, ''x''), (2, ''y''), (3, ''z'')) as t(id, f)');
	PREPARE some_view_returned AS SELECT * FROM public.some_view ORDER BY id;

	RETURN query SELECT * FROM check_test(
		results_eq('some_view_returned', 'some_view_should_be'),
		TRUE,
		'mock of some_view should return expected result');
END;
$$ LANGUAGE plpgsql;

select * from tests.test_view_mocking();

---- Finish the tests and clean up.
SELECT * FROM finish();
ROLLBACK;
