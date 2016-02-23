-module(invoices).

-record(invoice, {id, amount, memo, title, merchant, subsidiary}).

%%% Types
-opaque invoice() :: #invoice{
			id         :: integer(),
			amount     :: integer(),
			memo       :: string(),
			title      :: string(),
			merchant   :: merchants:merchant(),
			subsidiary :: subsidiaries:subsidiary()
		       }.
-export_type([invoice/0]).

%%% API
-export([new/5, merchant/1, marshal/2, unmarshal/2]).

-spec new(integer(), string(), subsidiaries:subsidiary(), merchants:merchant(), map()) -> invoice().
new(Amount, Memo, Subsidiary, Merchant, Options) ->
  #invoice{
     subsidiary = Subsidiary,
     merchant   = Merchant,
     amount     = Amount,
     memo       = Memo,
     title      = maps:get(title, Options, ""),
     id         = maps:get(id, Options, undefined)
  }.

-spec merchant(invoice()) -> merchants:merchant().
merchant(#invoice{merchant = Merchant}) ->
  Merchant.

-spec marshal(invoice(), json | sql) -> jsx:json_text() | iodata().
marshal(Invoice, json) ->
  Attrs = to_proplist(Invoice),
  jsx:encode(Attrs);
marshal(Invoice, sql) ->
  InvoicePropList = to_proplist(Invoice),
  Attrs = [
    {merchant_id, merchants:id(invoices:merchant(Invoice))}
  ] ++ proplists:delete(merchant, InvoicePropList),
  sqerl:sql({insert, invoices, Attrs}, true).

-spec unmarshal(jsx:json_text(), json) -> invoice().
unmarshal(InvoiceData, json) ->
  jsx:decode(InvoiceData, [return_maps, {labels, atom}]);
unmarshal(InvoiceData, sql) ->
  InvoiceData.

to_proplist(Invoice) ->
  [{amount, Invoice#invoice.amount},
   {memo, Invoice#invoice.memo},
   {title, Invoice#invoice.title},
   {merchant, Invoice#invoice.merchant}].
